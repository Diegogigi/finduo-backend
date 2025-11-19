# 🔍 Cómo Obtener la URL de tu Backend en Railway

## Railway genera automáticamente una URL cuando despliega tu servicio.

### Pasos para Encontrar la URL:

#### Opción 1: Desde el Dashboard Principal

1. Ve a **https://railway.app**
2. Inicia sesión
3. Verás tu proyecto en el dashboard
4. **Click directamente en el servicio** (el cuadro que muestra tu backend)
5. En la parte superior verás una sección con **"Domains"** o un botón que dice **"Generate Domain"**
6. Si ya hay un dominio, verás algo como:
   ```
   https://finduo-backend-production-xxxx.up.railway.app
   ```
7. **Copia esa URL completa**

#### Opción 2: Desde Settings

1. Ve a tu proyecto en Railway
2. Click en el **servicio desplegado** (el que tiene tu código)
3. Ve a la pestaña **"Settings"** (en el menú lateral)
4. Busca la sección **"Networking"** o **"Domains"**
5. Ahí verás la URL generada

#### Opción 3: Si NO aparece ninguna URL

Si no ves una URL, Railway puede estar aún desplegando:

1. Ve a la pestaña **"Deployments"** en tu servicio
2. Verifica el estado:

   - ✅ **"Success"** = Despliegue completo
   - 🔄 **"Building"** o **"Deploying"** = Aún en proceso
   - ❌ **"Failed"** = Error, revisa los logs

3. Si está en proceso, espera unos minutos y recarga la página

4. Si el despliegue falló:
   - Click en el deployment fallido
   - Revisa los **"Logs"** para ver el error
   - Verifica que las variables de entorno estén correctas

#### Opción 4: Generar un Dominio Personalizado

Si no aparece automáticamente:

1. En **Settings** → **Networking**
2. Click en **"Generate Domain"** o **"Add Domain"**
3. Railway generará una URL automáticamente

---

## ✅ Verificar que Funciona

Una vez que tengas la URL:

1. Abre en tu navegador: `https://TU-URL.up.railway.app/health`
2. Deberías ver: `{"status":"ok"}`
3. Si ves esto, ¡tu backend está funcionando! 🎉

---

## 🔧 Si el Despliegue Falla

Revisa los logs:

1. Ve a **Deployments**
2. Click en el deployment más reciente
3. Revisa los **"Build Logs"** y **"Deploy Logs"**
4. Errores comunes:
   - Variables de entorno faltantes
   - Error en el Dockerfile
   - Problemas con las dependencias

---

## 📝 Nota Importante

- La URL puede tardar 1-2 minutos en aparecer después del despliegue
- Railway puede cambiar la URL si eliminas y recreas el servicio
- La URL siempre será `https://` (no `http://`)
