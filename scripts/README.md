# Free-Market Suite Scripts

ملف سكربتات موحد لإدارة وتشغيل وإيقاف كامل منظومة Free-Market على نظام Windows.

## الملفات

| الملف | الوظيفة |
|---|---|
| `start-all.bat` | تشغيل جميع الأنظمة (الشحن + السوق) |
| `start-shipping.bat` | تشغيل نظام الشحن `free-market` (PostgreSQL + Flask API) |
| `start-market.bat` | تشغيل السوق الحرة `Manufacturers-market` (PostgreSQL + FastAPI) |
| `start-apps.bat` | تشغيل واجهة تطبيق الصين Flutter (اختياري) |
| `stop-all.bat` | إيقاف وإغلاق جميع الحاويات والخوادم |

## التشغيل

اسحب الملفات إلى مجلد `scripts` الرئيسي في جذر المشروع `D:\free-market\scripts`.

### تشغيل كل شيء
```bat
scripts\start-all.bat
```

### تشغيل نظام واحد فقط
```bat
scripts\start-shipping.bat     :: نظام الشحن فقط
scripts\start-market.bat       :: السوق الحرة فقط
scripts\start-apps.bat         :: واجهة تطبيق الصين (Flutter)
```

### إيقاف كل شيء وإغلاق الخادم
```bat
scripts\stop-all.bat
```

## الخدمات بعد التشغيل

| الخدمة | العنوان |
|---|---|
| Shipping API (Flask) | http://localhost:5000 |
| Health check الشحن | http://localhost:5000/health |
| Market API (FastAPI) | http://localhost:8002 |
| توثيق Market التفاعلي | http://localhost:8002/docs |
| PostgreSQL الشحن | localhost:5432 |
| PostgreSQL السوق | localhost:5543 |

## المتطلبات

- Docker + Docker Compose مثبتة ومشغلة.
- ملفات `.env` موجودة (يكفي نسخ `.env.example` إن غابت — السكربت يتحقق ويرشدك).
- لتشغيل `start-apps.bat` يلزم Flutter SDK على `PATH`.

## ملاحظات

- الإيقاف يحافظ على بيانات قواعد البيانات (volumes).
- لحذف قواعد البيانات نهائياً بمحض إرادتك:
  ```bat
  docker compose -f free-market\01_database_setup\docker-compose.yml down -v
  docker compose -f Manufacturers-market\database\docker-compose.yml down -v
  ```