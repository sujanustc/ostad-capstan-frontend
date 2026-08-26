# DEVOPS ENGINEERING DECISIONS & RATIONALE

**Application**: Support Chat Platform Frontend (`simple-vite-front`)  
**Repository**: `https://github.com/sujanustc/ostad-capstan-frontend`  
**Docker Hub**: `https://hub.docker.com/repositories/dasujandb`  
**Target Platform**: AWS EC2 (`13.203.161.35`) running K3s & Argo CD  

---

## 1. Source Control & Branching Strategy

We adopted a long-lived environment-branch model consisting of **`dev`**, **`stage`**, and **`prod`**:

* **`dev` branch**: Primary integration branch for development.
* **`stage` branch**: Pre-production environment. Promoted from `dev` via PR.
* **`prod` branch**: Production release branch. Promoted from `stage` via PR.

---

## 2. CI/CD & Deployment Trigger Strategy

* **Dev & Stage Environments (Manual Trigger)**:
  * Code pushes to `dev` or `stage` execute CI validation and Docker image build (`dasujandb/support-chat-frontend:${ENV}-${SHA}-${TIMESTAMP}`).
  * Deployment to the running Kubernetes environment requires an explicit **manual human decision** (triggered via GitHub Actions `workflow_dispatch` or manual Argo CD Application sync).

* **Production Environment (Automatic Trigger on PR Open)**:
  * Opening a Pull Request targeting `prod` automatically builds production containers (`nginx:alpine`), updates `k8s/prod/frontend.yaml`, and commits back.
  * Argo CD (with `automated` sync policy enabled for `prod`) instantly reconciles the cluster state.

---

## 3. Containerization & Versioning Scheme

* **Development Image (`Dockerfile.dev`)**: Vite dev server with hot reloading.
* **Production Image (`Dockerfile.prod`)**: Multi-stage Vite build + `nginx:alpine` static web server.
* **Traceable Versioning**: `dasujandb/support-chat-frontend:${ENV}-${GIT_COMMIT_SHA_SHORT}-${TIMESTAMP}`

---

## 4. Kubernetes & GitOps Delivery

* **Namespace**: `dev`, `stage`, `prod`
* **NodePorts**:
  * Dev: `30002`
  * Stage: `30012`
  * Prod: `30022`
* **Argo CD UI**: `https://13.203.161.35:30808`
