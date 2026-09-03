FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir \
    "flask>=3.0" \
    flask-cors \
    "flask-sqlalchemy>=3.1" \
    flask-migrate \
    sqlalchemy \
    "psycopg[binary,pool]" \
    python-dotenv \
    flask-jwt-extended \
    bcrypt \
    requests \
    httpx
COPY app ./app

ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
ENV PORT=5000
ENV FLASK_ENV=development

CMD ["python", "-m", "app.main"]
