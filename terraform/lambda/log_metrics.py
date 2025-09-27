# UA: Проста Lambda для "логування метрик" тренування (демо-логіка)
# EN: Simple Lambda for "logging training metrics" (demo logic)

import json
import os
import logging
import time
import random

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

def lambda_handler(event, context):
    """
    UA: Імітуємо обчислення метрик, логумо та повертаємо їх.
    EN: Simulate metric computation, log and return them.
    """
    logger.info("Logging metrics...")
    logger.info("Incoming event: %s", json.dumps(event))

    # Імітаційні метрики / Mock metrics
    metrics = {
        "accuracy": round(random.uniform(0.8, 0.99), 4),
        "loss": round(random.uniform(0.01, 0.2), 4),
        "timestamp": int(time.time()),
    }

    result = {
        "status": "ok",
        "step": "log_metrics",
        "received_from_previous": event,
        "metrics": metrics,
        "context": {
            "aws_request_id": getattr(context, "aws_request_id", None),
        },
    }
    logger.info("Metrics result: %s", json.dumps(result))
    return result
