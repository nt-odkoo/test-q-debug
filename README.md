# test-q-debug

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
