FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir \
	"fastapi>=0.140" \
	"uvicorn[standard]>=0.30" \
	"pydantic>=2.6" \
	pydantic-settings \
	"sqlalchemy>=2.0" \
	"psycopg[binary,pool]" \
	python-dotenv \
	"PyJWT>=2.8" \
	bcrypt \
	"httpx>=0.26"
COPY app ./app

ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
ENV PORT=8000
ENV APP_ENV=development

CMD ["python", "-m", "app.main"]
