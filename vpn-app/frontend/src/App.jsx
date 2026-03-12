import { useState, useEffect } from 'react'
import Usuarios from './pages/Usuarios'
import Configuracion from './pages/Configuracion'
import Logs from './pages/Logs'

function App() {
  const [pagina, setPagina] = useState('usuarios')

  return (
    <div>
      <header className="header">
        <div className="container">
          <h1>VPN Manager - WireGuard</h1>
        </div>
      </header>
      
      <main className="container">
        <nav style={{ marginBottom: '24px', display: 'flex', gap: '8px' }}>
          <button 
            className={`btn ${pagina === 'usuarios' ? 'btn-primary' : ''}`}
            onClick={() => setPagina('usuarios')}
          >
            Usuarios
          </button>
          <button 
            className={`btn ${pagina === 'configuracion' ? 'btn-primary' : ''}`}
            onClick={() => setPagina('configuracion')}
          >
            Configuración
          </button>
          <button 
            className={`btn ${pagina === 'logs' ? 'btn-primary' : ''}`}
            onClick={() => setPagina('logs')}
          >
            Logs
          </button>
        </nav>

        {pagina === 'usuarios' && <Usuarios />}
        {pagina === 'configuracion' && <Configuracion />}
        {pagina === 'logs' && <Logs />}
      </main>
    </div>
  )
}

export default App
