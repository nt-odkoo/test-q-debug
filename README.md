# test-q-debug

Don't forget this command.
```
uv lock
```

```
diff --git a/docker-compose.yaml b/docker-compose.yaml
index 45ead7a..4646012 100644
--- a/docker-compose.yaml
+++ b/docker-compose.yaml
@@ -5,6 +5,8 @@ x-common: &common
       - UV_NO_EDITABLE=0
   env_file:
     - .env
+  environment:
+    - PYTHONUNBUFFERED=1
   networks:
     - default
   depends_on:
@@ -26,9 +28,9 @@ services:
     command: >
       -p 15432
       -c log_destination=stderr
-      -c log_statement=all
-      -c log_connections=on
-      -c log_disconnections=on
+      -c log_statement=none
+      -c log_connections=off
+      -c log_disconnections=off
       -c shared_preload_libraries=pg_cron
 
   sso:
@@ -47,21 +49,21 @@ services:
     command: ["-m", "uvicorn", "sso.main:app", "--host", "0.0.0.0", "--reload"]
     user: root
 
 
   surgical:
     <<: *common
@@ -72,30 +74,44 @@ services:
     container_name: surgical
     ports:
       - 8002:8000
+      - 5678:5678
     volumes:
       - ./services/surgical:/app/surgical
       - ./libs:/app/libs
       - ./services/sso:/app/sso
       - $HOME/.aws/:/root/.aws:ro
-    command: ["-m", "uvicorn", "surgical.main:app", "--host", "0.0.0.0", "--reload"]
+    command:
+      [
+        "-m",
+        "debugpy",
+        "--listen",
+        "0.0.0.0:5678",
+        "-m",
+        "uvicorn",
+        "surgical.main:app",
+        "--host",
+        "0.0.0.0",
+        "--reload",
+      ]
     user: root
 
   nginx:
     image: nginx:latest
     
     
diff --git a/services/surgical/Dockerfile b/services/surgical/Dockerfile
index 4b074a6..90110b5 100644
--- a/services/surgical/Dockerfile
+++ b/services/surgical/Dockerfile
@@ -21,7 +21,11 @@ WORKDIR /app
 COPY .python-version ./scripts/install_python.sh ./
 RUN ./install_python.sh
 
+# Workspace members' pyproject.toml files are required for sync
 COPY ./libs ./libs
+COPY ./services/sso/pyproject.toml ./services/sso/pyproject.toml
+COPY ./services/surgical/pyproject.toml ./services/surgical/pyproject.toml
+
 RUN --mount=type=cache,target=/root/.cache/uv \
   --mount=type=bind,source=uv.lock,target=uv.lock \
   --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
   
   
diff --git a/services/surgical/pyproject.toml b/services/surgical/pyproject.toml
index 173f156..ea04b46 100644
--- a/services/surgical/pyproject.toml
+++ b/services/surgical/pyproject.toml
@@ -5,6 +5,7 @@ description = "Add your description here"
 readme = "README.md"
 requires-python = ">=3.13"
 dependencies = [
+  "debugpy>=1.8.12",
   "email-validator>=2.2.0",
   "fastapi-filter[sqlalchemy]>=2.0.1",
   "fastapi-pagination[sqlalchemy]>=0.12.34",
```


```
> toml file aa ашиглаад хаана яаж install хийж байгаа вэ docker file уудыг уншаад гаргаад өгөөч        
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

ℹ Gemini CLI update available! 0.35.2 → 0.35.3
  Installed with npm. Attempting to automatically update now...

ℹ Update successful! The new version will be used on your next run.
✦ Би төслийн бүтэц болон Dockerfile-уудыг судалж үзээд pyproject.toml файлуудыг хэрхэн ашиглаж байгааг
  тайлбарлая.

  Энэ төсөлд Poetry эсвэл uv ашиглан хамаарлуудыг (dependencies) удирдаж байгаа бөгөөд Dockerfile-ууд
  дээр дараах байдлаар суулгаж байна:

  1. SSO үйлчилгээний Dockerfile (services/sso/Dockerfile)
  Би эхлээд SSO үйлчилгээний Dockerfile-ыг уншиж үзье. Энэ нь бусад үйлчилгээнүүдийн ерөнхий жишээ болох
  байх.

  2. Бусад үйлчилгээнүүд
  opereco, reflet, surgical зэрэг үйлчилгээнүүд бүгд өөрийн гэсэн Dockerfile-тай байна.

  Дэлгэрэнгүй мэдээлэл авахын тулд зарим Dockerfile-уудыг уншиж үзье.
╭──────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  ReadFile services/sso/Dockerfile                                                              │
│                                                                                                  │
│                                                                                                  │
│ ✓  ReadFile services/reflet/Dockerfile                                                           │
│                                                                                                  │
╰──────────────────────────────────────────────────────────────────────────────────────────────────╯
╭──────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  ReadFile services/sso/Dockerfile                                                              │
│                                                                                                  │
✦ Танай төсөл нь uv (Astral-аас гаргасан Python-ы маш хурдан package manager) ашиглан хамаарлуудыг
  (dependencies) удирдаж байна. Dockerfile-уудаас харахад pyproject.toml файлуудыг дараах байдлаар
  суулгаж байна:

  1. Хаана, яаж суулгаж байна вэ?
  Dockerfile-ууд дээр uv sync командыг ашиглан хамаарлуудыг суулгадаг.

   * Суулгах орчин: ENV UV_PROJECT_ENVIRONMENT=/usr/local гэж тохируулсан тул Virtual Environment
     үүсгэлгүйгээр шууд системийн /usr/local зам руу суулгаж байна. Энэ нь Docker image-ийг илүү хөнгөн
     болгодог.
   * Суулгах процесс:
       1. Эхлээд libs/ доторх дотоод сангуудыг (internal libraries) хуулж авна.
       2. Үндсэн pyproject.toml болон uv.lock файлуудыг Docker-ын "mount bind" технологиор түр холбож
          (--mount=type=bind), хамаарлуудыг суулгана.
       3. uv sync --frozen --no-install-project --no-dev --package <service_name> командаар зөвхөн
          тухайн үйлчилгээнд (sso, reflet гэх мэт) шаардлагатай сангуудыг суулгадаг.

  2. Dockerfile-ын бүтэц (Жишээ нь sso үйлчилгээ):

    1 # 1. uv хэрэгслийг ghcr.io-оос хуулж авна
    2 COPY --from=ghcr.io/astral-sh/uv:0.7.21 /uv /uvx /bin/
    3
    4 # 2. Дотоод сангуудыг хуулна (libs/qt-common, libs/qt-auth гэх мэт)
    5 COPY ./libs ./libs
    6
    7 # 3. Хамаарлуудыг суулгах (Cache болон Bind ашиглан)
    8 RUN --mount=type=cache,target=/root/.cache/uv \
    9     --mount=type=bind,source=uv.lock,target=uv.lock \
   10     --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
   11     uv sync --frozen --no-install-project --no-dev --package sso
   12
   13 # 4. Үндсэн кодоо хуулна
   14 COPY services/sso ./sso

  3. Онцлох зүйлс:
   * Monorepo бүтэц: Танай төсөл нь олон үйлчилгээ болон сангуудыг нэг дор агуулсан Monorepo бүтэцтэй.
     Үндсэн pyproject.toml файл нь бүх үйлчилгээнүүдийг (Workspace) нэгтгэж удирддаг.
   * Дотоод сангууд: libs/ хавтас доторх сангууд (жишээ нь qt-auth, qt-common) нь үйлчилгээнүүдийн
     хооронд хуваалцаж ашиглагддаг.
   * Distroless Image: Эцсийн байдлаар кодоо ажиллуулахдаа gcr.io/distroless/cc-debian12 ашигладаг нь
     аюулгүй байдал болон хэмжээний хувьд маш сайн сонголт юм (дотор нь shell байхгүй, зөвхөн
     шаардлагатай файлууд л байна).

  Товчхондоо: uv ашиглан үндсэн pyproject.toml-оос тухайн үйлчилгээнд хамаарах хэсгийг нь ялгаж
  /usr/local замд суулгаж байна.
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
 > @services/surgical/pyproject.toml энэ дээр би debugpy гэж нэмсэн боловч install хийхгүй no module    
   named debugpy гэсэн алдаа гараад байна би юун дээр алдаа гаргасан байж болох вэ? bashrc, zhrc гээс   
   болно гэж байх уу?                                                                                   
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
╭──────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  ReadManyFiles Will attempt to read and concatenate files using patterns: services/surgical/p… │
│                                                                                                  │
│ ReadManyFiles Result (Target Dir: /home/odkoo/workspaces/quotomy/quotomy-core)                   │
│                                                                                                  │
│ Successfully read and concatenated content from 1 file(s).                                       │
│                                                                                                  │
│ Processed Files:                                                                                 │
│  - services/surgical/pyproject.toml                                                              │
╰──────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ Таны debugpy суулгагдахгүй байгаа хэд хэдэн шалтгаан байж болно. Хамгийн гол нь энэ төсөл uv workspace
  (monorepo) бүтэцтэй учраас зөвхөн нэг файлд өөрчлөлт оруулаад орхих нь хангалтгүй байдаг.

  1. uv.lock файлыг шинэчлээгүй байх (Хамгийн магадлалтай)
  Та services/surgical/pyproject.toml файлд debugpy нэмсэн ч, төслийн үндсэн хавтсанд байгаа uv.lock
  файлыг шинэчлээгүй байж магадгүй. Dockerfile дээр uv sync --frozen команд ашиглаж байгаа бөгөөд энэ нь
  "lock файл дотор юу байна, яг тэрийг л суулгана" гэсэн үг юм.

  Шийдэл: Үндсэн хавтсандаа (root directory) очиод дараах командыг ажиллуулж uv.lock файлаа шинэчилнэ
  үү:
   1 uv lock
  Үүний дараа Docker image-ээ дахин build хийх хэрэгтэй.

  2. Docker Build Context-д surgical/pyproject.toml ороогүй байх
  Таны Dockerfile дээр uv sync --package surgical гэж ажиллуулж байгааг харлаа. uv нь surgical багцыг
  суулгахын тулд тэр хавтсан дахь pyproject.toml-ыг унших шаардлагатай.

  Хэрэв таны Dockerfile-д services/surgical/pyproject.toml файлыг uv sync хийхээс өмнө хуулаагүй эсвэл
  mount хийгээгүй бол uv хуучин тохиргоог ашиглаад байж магадгүй. 

  surgical/Dockerfile-ыг шалгаад үзээрэй. sso дээр бол ингэж харагдаж байна:

   1 RUN --mount=type=cache,target=/root/.cache/uv \
   2   --mount=type=bind,source=uv.lock,target=uv.lock \
   3   --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
   4   # Энд surgical-ын pyproject.toml бас байх шаардлагатай байж магадгүй
   5   uv sync --frozen --no-install-project --no-dev --package surgical

  3. Багцын нэрийг шалгах
  debugpy нь surgical үйлчилгээний dependencies дотор байгаа эсэхийг баталгаажуулаарай. Таны илгээсэн
  кодонд бол зөв байна:
   1 dependencies = [
   2   "debugpy>=1.8.12",
   3   ...
   4 ]

  4. .bashrc эсвэл .zshrc-ээс болох уу?
  Үгүй, энэ нь бараг боломжгүй. Учир нь суулгалт Docker дотор явагдаж байгаа бөгөөд Docker нь таны
  компьютерын .bashrc тохиргоог ашигладаггүй. Харин та локал орчиндоо (Docker биш) ажиллуулж байгаа бол
  uv ашиглаж буй Virtual Environment (.venv) идэвхтэй байгаа эсэхийг л шалгах хэрэгтэй.

  ---

  Зөвлөмж (Дараах дарааллаар үзээрэй):

   1. Локалоор lock хийх: Root хавтсанд uv lock ажиллуулж, uv.lock өөрчлөгдсөн эсэхийг шалгах.
   2. Docker-оо Cache-гүй Build хийх: Заримдаа Docker өмнөх layer-үүдийг cache-ээс аваад байдаг тул:

   1     docker-compose build --no-cache surgical
   3. Dockerfile-ыг шалгах: uv sync хийх үед services/surgical/pyproject.toml файл Docker дотор харагдаж
      байгаа эсэхийг нягтлах. (Хэрэв та surgical/Dockerfile-ыг уншуулаад өгвөл би илүү тодорхой хэлж өгч
      чадна).

  Та services/surgical/Dockerfile болон root хавтсанд байгаа pyproject.toml файлуудыг уншуулах уу? Би яг
  ямар файл дутуу хуулагдаж байгааг хэлж өгье.

```
