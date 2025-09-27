# UA: Проста Lambda для "валідації" вхідних даних (демо-логіка)
# EN: Simple Lambda for "validating" input data (demo logic)

import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

def lambda_handler(event, context):
    """
    UA: Ехо-валідація — перевіряємо, що прийшов JSON, логумо метадані, повертаємо статус "ok".
    EN: Echo-style validation — ensure JSON input, log metadata, return "ok" status.
    """
    logger.info("Validating data...")
    logger.info("Incoming event: %s", json.dumps(event))

    # Демонстраційна умова відмови/помилки (за бажанням)
    # Demo failure guard (optional)
    if isinstance(event, dict) and event.get("fail_validate"):
        logger.error("Validation failed due to 'fail_validate' flag.")
        return {"status": "failed", "reason": "fail_validate flag set"}

    result = {
        "status": "ok",
        "step": "validate",
        "input_echo": event,
        "context": {
            "aws_request_id": getattr(context, "aws_request_id", None),
        },
    }
    logger.info("Validation result: %s", json.dumps(result))
    return result
