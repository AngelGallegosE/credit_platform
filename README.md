# Credit Platform - Sistema de Solicitudes de Crédito

Este proyecto es una plataforma para la gestión de solicitudes de crédito, desarrollada como parte de un proceso técnico. Incluye un backend robusto en Ruby on Rails y un frontend dinámico en React (Vite).

Se cumplio con TODA la funcionalidad requerida.
De los extras opcionales se cumplio con 2:
- Metricas y dashboards
- Auditoria detallada de cambios

## 🚀 Instrucciones de Instalación y Ejecución

### Requisitos Previos
- **Ruby:** 3.4.7
- **Node.js:** >= 18
- **PostgreSQL:** Versión 12 o superior
- **Redis:** Para Sidekiq y ActionCable
- **Docker/Kubectl:** (Opcional) Para despliegue en Kubernetes

### Configuración Rápida
He incluido un `Makefile` en la raíz para simplificar las tareas comunes:

1. **Instalar dependencias:**
   ```bash
   make install
   ```

2. **Configurar la Base de Datos:**
   Asegúrate de tener PostgreSQL corriendo y ejecuta:
   ```bash
   make migrate
   ```

3. **Ejecutar la Aplicación:**
   Este comando levanta tanto el backend (puerto 3000) como el frontend (puerto 5173):
   ```bash
   make run
   ```

4. **Ejecutar Pruebas:**
   ```bash
   make test
   ```

---

## 🛠 Decisiones Técnicas

- **Ruby on Rails (API Mode):** Elegido por su rapidez de desarrollo y madurez en el manejo de lógica de negocio compleja. Se utiliza en modo API para separar completamente la lógica del servidor de la interfaz.
- **React + Vite:** Para una interfaz de usuario reactiva y rápida. Vite ofrece una experiencia de desarrollo superior comparado con CRA(create react app).
- **Sidekiq + Redis:** Para el procesamiento asíncrono. Las validaciones de crédito y comunicaciones externas se manejan en background para no bloquear el flujo del usuario.
- **ActionCable:** Implementado para notificaciones en tiempo real (por ejemplo, cuando el estado de una solicitud cambia tras una validación asíncrona).
- **JWT (Devise + Devise-JWT):** Para autenticación stateless, permitiendo escalabilidad horizontal.

---

## 📊 Modelo de Datos

- **User:** Gestiona la autenticación y perfiles. Tiene una relación `has_many` con `CreditApplication`.
- **CreditApplication:** El corazón del sistema. Almacena montos, estados (enum), país y datos bancarios. Utiliza ActiveStorage para los documentos de identidad.
- **CreditApplicationEvent:** Sistema de auditoría (logs) que registra cada cambio importante en las solicitudes para trazabilidad.
- **JwtDenylist:** Almacena los tokens revocados para mayor seguridad en el cierre de sesiones.

---

## 🔒 Consideraciones de Seguridad

1. **Autenticación JWT:** Tokens con tiempo de expiración y sistema de denylist para revocación inmediata al hacer logout.
2. **Sanitización de Datos:** Rails protege automáticamente contra inyecciones SQL y ataques XSS (aunque en modo API el riesgo de XSS es menor).
3. **Variables de Entorno:** Uso de `.env` y Secretos de Kubernetes para manejar claves sensibles (JWT secrets, DB passwords).
4. **CORS:** Configurado específicamente para permitir solo el origen del frontend.

---

## 📈 Escalabilidad y Grandes Volúmenes

1. **Caché con Redis:** Se implementó caché de fragmentos y de bajo nivel para los conteos de analíticas, reduciendo la carga en la base de datos principal.
2. **Índices en BD:** Las tablas de solicitudes y eventos tienen índices en columnas de búsqueda frecuente (status, country, user_id).
3. **Escalabilidad Horizontal:**
   - El backend es stateless (gracias a JWT).
   - Los manifiestos de Kubernetes incluyen `replicas: 2` y están preparados para Horizontal Pod Autoscaling (HPA).
4. **Procesamiento Asíncrono:** El uso de Sidekiq permite manejar miles de validaciones simultáneas sin degradar la respuesta de la API.

---

## 🏗 Estrategia de Concurrencia, Colas y Webhooks

- **Concurrencia:** Manejada a nivel de servidor con Puma (threads) y a nivel de workers con Sidekiq.
- **Colas:**
  - `default`: Tareas estándar.
  - `validations`: (Configurable) Para procesos pesados de validación de reglas de crédito.
- **Webhooks:** Se incluye un endpoint (`/api/v1/webhooks/banking_data`) para recibir datos de proveedores bancarios externos. Este proceso es asíncrono: el webhook recibe el dato, encola un job y responde `200 OK` inmediatamente.
- **Caché:** Estrategia de invalidación basada en callbacks de modelo para asegurar que las analíticas estén siempre actualizadas pero sean rápidas de consultar.

---

## ☸️ Despliegue en Kubernetes (k8s)

Los archivos de configuración se encuentran en `infra/k8s/`. Incluyen:

- **Namespace:** `credit-platform`.
- **Base de Datos:** PostgreSQL con volúmenes persistentes.
- **Caché/Mensajería:** Redis para Sidekiq y ActionCable.
- **Backend:** Deployment de la API y un Deployment separado para los Workers de Sidekiq.
- **Frontend:** Servido a través de un deployment dedicado.
- **Ingress:** Configurado para manejar el tráfico mediante `credit-platform.local` y `api.credit-platform.local`.

Para desplegar:
```bash
make deploy-k8s
```

*Nota: Asegúrate de tener configurado tu contexto de kubectl y un controlador de Ingress (como Nginx) instalado.*
