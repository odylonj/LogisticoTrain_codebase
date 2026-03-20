from flask import Blueprint

health_controller = Blueprint('health', __name__)


@health_controller.route("/health", methods=['GET'])
def health():
    return {"status": "UP"}
