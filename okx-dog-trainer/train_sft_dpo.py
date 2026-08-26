"""
OKX-Dog 量化模型 SFT 微调与 DPO 强化训练脚本 (基于 Unsloth / Hugging Face TRL)
模块: okx-dog-trainer/train_sft_dpo.py
支持本地 GPU / Linux 服务器一键极速训练与 GGUF 导出
"""

import argparse
import os
import torch
from datasets import load_dataset

def train_sft(
    base_model_name: str,
    dataset_path: str,
    output_dir: str,
    max_seq_length: int = 2048,
    epochs: int = 3,
    batch_size: int = 2,
    learning_rate: float = 2e-4,
    export_gguf: bool = True
):
    print(f"[*] 正在加载基座模型: {base_model_name}")
    try:
        from unsloth import FastLanguageModel
        use_unsloth = True
    except ImportError:
        print("[!] 未检测到 unsloth，将使用标准 Hugging Face 模式 (建议在 Colab 使用 Unsloth 加速)")
        use_unsloth = False

    if use_unsloth:
        model, tokenizer = FastLanguageModel.from_pretrained(
            model_name=base_model_name,
            max_seq_length=max_seq_length,
            load_in_4bit=True,
            dtype=None,
        )

        model = FastLanguageModel.get_peft_model(
            model,
            r=16,
            target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
            lora_alpha=16,
            lora_dropout=0,
            bias="none",
            use_gradient_checkpointing="unsloth",
            random_state=3407,
        )
    else:
        from transformers import AutoModelForCausalLM, AutoTokenizer
        from peft import LoraConfig, get_peft_model
        tokenizer = AutoTokenizer.from_pretrained(base_model_name)
        model = AutoModelForCausalLM.from_pretrained(base_model_name, torch_dtype=torch.float16, device_map="auto")
        peft_config = LoraConfig(
            r=16,
            lora_alpha=16,
            target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
            lora_dropout=0.05,
            bias="none",
            task_type="CAUSAL_LM"
        )
        model = get_peft_model(model, peft_config)

    print(f"[*] 加载微调数据集: {dataset_path}")
    dataset = load_dataset("json", data_files=dataset_path, split="train")

    def formatting_prompts_func(examples):
        instructions = examples["instruction"]
        inputs = examples["input"]
        outputs = examples["output"]
        texts = []
        for instruction, inp, output in zip(instructions, inputs, outputs):
            text = f"<|im_start|>system\n{instruction}<|im_end|>\n<|im_start|>user\n{inp}<|im_end|>\n<|im_start|>assistant\n{output}<|im_end|>"
            texts.append(text)
        return {"text": texts}

    dataset = dataset.map(formatting_prompts_func, batched=True)

    from trl import SFTTrainer
    from transformers import TrainingArguments

    training_args = TrainingArguments(
        per_device_train_batch_size=batch_size,
        gradient_accumulation_steps=4,
        warmup_steps=10,
        num_train_epochs=epochs,
        learning_rate=learning_rate,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        logging_steps=5,
        optim="adamw_8bit",
        weight_decay=0.01,
        lr_scheduler_type="linear",
        seed=3407,
        output_dir=output_dir,
    )

    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=dataset,
        dataset_text_field="text",
        max_seq_length=max_seq_length,
        dataset_num_proc=2,
        packing=False,
        args=training_args,
    )

    print("[*] 开始训练...")
    trainer.train()
    print(f"[+] 训练完成！保存 LoRA 权重至: {output_dir}")
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)

    if export_gguf and use_unsloth:
        print("[*] 正在导出 Ollama GGUF 格式 (Q4_K_M)...")
        gguf_path = os.path.join(output_dir, "gguf")
        model.save_pretrained_gguf(gguf_path, tokenizer, quantization_method="q4_k_m")
        print(f"[+] GGUF 导出完成: {gguf_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="OKX-Dog 量化模型微调训练工具")
    parser.add_argument("--base-model", type=str, default="unsloth/Qwen2.5-7B-Instruct", help="基座模型名称")
    parser.add_argument("--dataset", type=str, required=True, help="SFT 训练数据集路径 (.jsonl)")
    parser.add_argument("--output-dir", type=str, default="./output_model", help="微调输出目录")
    parser.add_argument("--epochs", type=int, default=3, help="训练轮数")
    parser.add_argument("--batch-size", type=int, default=2, help="单卡批大小")
    parser.add_argument("--no-gguf", action="store_true", help="不导出 GGUF")
    args = parser.parse_args()

    train_sft(
        base_model_name=args.base_model,
        dataset_path=args.dataset,
        output_dir=args.output_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        export_gguf=not args.no_gguf
    )
