const { app, BrowserWindow, Menu, shell } = require('electron')
const path = require('path')
const http  = require('http')

const DEV_URL  = 'http://localhost:5173'
const PROD_URL = 'http://localhost:5173'   // vite preview yoki dev server

let mainWindow

// Server tayyor bo'lguncha kutish
function waitForServer(url, maxWait = 30) {
  return new Promise((resolve) => {
    let tries = 0
    const check = () => {
      http.get(url, () => resolve(true)).on('error', () => {
        if (++tries < maxWait) setTimeout(check, 1000)
        else resolve(false)
      })
    }
    check()
  })
}

async function createWindow() {
  mainWindow = new BrowserWindow({
    width:     1280,
    height:    800,
    minWidth:  900,
    minHeight: 600,
    title:     'Kafe POS',
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration:  false,
      contextIsolation: true,
      webSecurity:      false,   // lokal API uchun kerak
    },
  })

  // Menu ni yashirish
  Menu.setApplicationMenu(null)

  // Yuklanish ekrani
  mainWindow.loadURL(`data:text/html;charset=utf-8,
    <html>
      <body style="margin:0;background:#0F172A;display:flex;flex-direction:column;
                   align-items:center;justify-content:center;height:100vh;
                   font-family:system-ui,sans-serif">
        <div style="font-size:48px;margin-bottom:16px">☕</div>
        <div style="color:#F97316;font-size:22px;font-weight:800">Kafe POS</div>
        <div style="color:#94A3B8;font-size:14px;margin-top:12px">Server kutilmoqda...</div>
        <div style="margin-top:24px;width:200px;height:4px;background:#1E293B;border-radius:4px;overflow:hidden">
          <div style="height:100%;background:#F97316;border-radius:4px;
                      animation:load 1.5s ease-in-out infinite"
               id="bar"></div>
        </div>
        <style>
          @keyframes load {
            0%   { width:0% }
            50%  { width:70% }
            100% { width:0% }
          }
        </style>
      </body>
    </html>
  `)

  // Server tayyor bo'lguncha kut
  const ready = await waitForServer(DEV_URL)
  if (ready) {
    mainWindow.loadURL(DEV_URL)
  } else {
    mainWindow.loadURL(`data:text/html;charset=utf-8,
      <html>
        <body style="margin:0;background:#0F172A;display:flex;flex-direction:column;
                     align-items:center;justify-content:center;height:100vh;
                     font-family:system-ui,sans-serif">
          <div style="font-size:48px;margin-bottom:16px">⚠️</div>
          <div style="color:#EF4444;font-size:20px;font-weight:700">Server ishlamayapti!</div>
          <div style="color:#94A3B8;font-size:13px;margin-top:10px;text-align:center;max-width:300px">
            OpenServer va <b style="color:#F97316">npm run dev</b>ni ishga tushiring,
            keyin dasturni qayta oching.
          </div>
          <button onclick="location.reload()"
            style="margin-top:20px;background:#F97316;color:#fff;border:none;
                   border-radius:8px;padding:10px 24px;font-size:14px;
                   font-weight:700;cursor:pointer">
            Qayta urinish
          </button>
        </body>
      </html>
    `)
  }

  // Tashqi linklar brauzarda ochilsin
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url)
    return { action: 'deny' }
  })
}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow()
})
