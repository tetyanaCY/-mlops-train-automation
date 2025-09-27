# ML Ops — Automated Model Training via Terraform + Step Functions + GitLab CI
*(UA/EN below; двомовна інструкція)*

---

## 🇺🇦 Опис

Цей приклад показує, як автоматизувати **тренування ML-моделей** через **AWS Step Functions** із двома Lambda-кроками (ValidateData → LogMetrics), розгорнутими за допомогою **Terraform**, та запускати пайплайн автоматично з **GitLab CI** при `push`.

### Архітектура (спрощено)
1. **Step Function (STANDARD)**: послідовно викликає Lambda-функції:
   - `ValidateData` → `LogMetrics`
2. **Lambda (Python)**:
   - `validate.py` — ехо-алідація вхідного JSON
   - `log_metrics.py` — імітує підрахунок та логування метрик
3. **Terraform** створює усі IAM ролі, Lambda та Step Function.
4. **GitLab CI** викликає `aws stepfunctions start-execution` при кожному `push`.

---

## 🇺🇦 Підготовка

### 1) Збірка ZIP-архівів Lambda
```bash
cd terraform/lambda
zip validate.zip validate.py
zip log_metrics.zip log_metrics.py

Trigger CI 2025-09-27T17:56:19
