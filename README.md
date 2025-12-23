# Credit Platform - Sistema de Solicitudes de Crédito

Incluye un backend en Ruby on Rails y un frontend dinámico en React (Vite).

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

### 🔑 Credenciales de Prueba
Una vez ejecutadas las migraciones (que incluyen los seeds), puedes usar las siguientes cuentas:

| Rol | Correo | Contraseña |
| :--- | :--- | :--- |
| **Admin** | `admin@gmail.com` | `asdf1234` |
| **Usuario** | `user@gmail.com` | `asdf1234` |

---

## 🛠 Decisiones Técnicas

- **Ruby on Rails (API Mode):** Elegido por su rapidez de desarrollo y madurez en el manejo de lógica de negocio compleja. Se utiliza en modo API para separar completamente la lógica del servidor de la interfaz.
- **React + Vite:** Para una interfaz de usuario reactiva y rápida. Vite ofrece una experiencia de desarrollo superior comparado con CRA(create react app).
- **Sidekiq + Redis:** Para el procesamiento asíncrono. Las validaciones de crédito y comunicaciones externas se manejan en background para no bloquear el flujo del usuario.
- **ActionCable (WebSockets):** Implementado para notificaciones en tiempo real. Los usuarios reciben actualizaciones automáticas cuando cambia el estado de sus solicitudes de crédito, permitiendo una experiencia reactiva sin necesidad de recargar la página.
- **JWT (Devise + Devise-JWT):** Para autenticación stateless, permitiendo escalabilidad horizontal.

---

## 🎨 Patrones de Diseño

### Patrones Nativos de Rails

El proyecto utiliza los siguientes patrones que Rails incluye por defecto:

- **Active Record Pattern:** Los modelos (`User`, `CreditApplication`, `CreditApplicationEvent`) encapsulan tanto la lógica de negocio como el acceso a la base de datos, proporcionando una interfaz orientada a objetos para las operaciones de persistencia.
- **MVC (Model-View-Controller):** Aunque en modo API no hay vistas tradicionales, se mantiene la separación de responsabilidades: los modelos manejan la lógica de negocio, los controladores gestionan las peticiones HTTP y las respuestas JSON.
- **Callbacks:** Utilizados en los modelos para ejecutar lógica automática en momentos específicos del ciclo de vida (por ejemplo, `before_save`, `after_create`).
- **Scopes:** Definidos en los modelos para encapsular consultas comunes y reutilizables, mejorando la legibilidad y mantenibilidad del código.
- **Concerns:** Módulos compartidos que permiten extraer y reutilizar lógica común entre modelos, siguiendo el principio DRY (Don't Repeat Yourself).

### Patrones Adicionales Implementados

- **Strategy Pattern:** Implementado para seleccionar las validaciones de crédito según el país. Cada país (México, Portugal) tiene su propia estrategia de validación, permitiendo que el sistema seleccione dinámicamente el conjunto de reglas apropiado sin modificar el código principal y que sea facil agregar mas paises.
- **Specification Pattern:** Utilizado para disparar las validaciones específicas de cada país. Este patrón permite encapsular las reglas de negocio como especificaciones independientes y combinables, facilitando la evaluación de condiciones complejas de manera declarativa y testeable.

---

## 📊 Modelo de Datos

- **User:** Gestiona la autenticación y perfiles. Tiene una relación `has_many` con `CreditApplication`.
- **CreditApplication:** El corazón del sistema. Almacena montos, estados (enum), país y datos bancarios. Utiliza ActiveStorage para los documentos de identidad. **La tabla está particionada por país** (México y Portugal) para optimizar las consultas y mejorar el rendimiento en grandes volúmenes de datos.
- **CreditApplicationEvent:** Sistema de auditoría que registra automáticamente cada cambio en las solicitudes de crédito mediante un **trigger de base de datos**. Este trigger se ejecuta en cada modificación (INSERT, UPDATE, DELETE) de la tabla `credit_applications`, garantizando trazabilidad completa sin depender de la lógica de la aplicación.
- **JwtDenylist:** Almacena los tokens revocados para mayor seguridad en el cierre de sesiones.

---

## 🔒 Consideraciones de Seguridad

1. **Autenticación JWT:** Tokens con tiempo de expiración y sistema de denylist para revocación inmediata al hacer logout.
2. **Control de Acceso:** Solo los usuarios con rol de administrador pueden eliminar solicitudes de crédito, garantizando la integridad de los datos y cumplimiento normativo.
3. **Sanitización de Datos:** Rails protege automáticamente contra inyecciones SQL y ataques XSS (aunque en modo API el riesgo de XSS es menor).
4. **Variables de Entorno:** Uso de `.env` y Secretos de Kubernetes para manejar claves sensibles (JWT secrets, DB passwords).
5. **CORS:** Configurado específicamente para permitir solo el origen del frontend.

---

## 📈 Escalabilidad y Grandes Volúmenes

1. **Caché con Redis:** Se implementó caché de fragmentos y de bajo nivel para los conteos de analíticas, reduciendo la carga en la base de datos principal.
2. **Índices en BD:** Las tablas de solicitudes y eventos tienen índices en columnas de búsqueda frecuente (status, country, user_id).
3. **Particionamiento por País:** La tabla `credit_applications` está particionada por país (México y Portugal), lo que permite:
   - Consultas más rápidas al reducir el volumen de datos escaneados
   - Mantenimiento independiente de particiones
   - Mejor rendimiento en operaciones de lectura y escritura por región
4. **Escalabilidad Horizontal:**
   - El backend es stateless (gracias a JWT).
   - Los manifiestos de Kubernetes incluyen `replicas: 2` y están preparados para Horizontal Pod Autoscaling (HPA).
5. **Procesamiento Asíncrono:** El uso de Sidekiq permite manejar miles de validaciones simultáneas sin degradar la respuesta de la API.

---

## 📊 Métricas y Dashboards

El sistema incluye un dashboard de métricas que permite visualizar y analizar el estado de las solicitudes de crédito:

- **Gráfica de Barras por País:** Visualización que muestra el número de solicitudes de crédito agrupadas por país (México y Portugal) y desglosadas por estado (pendiente, aprobada, rechazada, etc.). Esta visualización permite a los administradores tener una vista rápida del volumen de solicitudes y su distribución por estado en cada región.

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
