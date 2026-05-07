import { useState, useEffect, useCallback, useRef } from 'react';
import { fetchWireguardStatus, formatBytes, formatTimeAgo } from '../services/wireguardService';

const REFRESH_INTERVAL = 15000; // 15 segundos

// ── Sub-componentes ───────────────────────────────────────────

function StatusDot({ active }) {
  return (
    <span style={{
      display: 'inline-block',
      width: 10, height: 10,
      borderRadius: '50%',
      background: active ? 'var(--success)' : 'var(--danger)',
      boxShadow: active ? '0 0 0 3px rgba(16,185,129,0.2)' : 'none',
      marginRight: 8,
      flexShrink: 0,
    }} />
  );
}

function StatCard({ label, value, color, icon }) {
  const valStr = String(value ?? '');
  // Reduce font size progressively for longer values
  const fontSize = valStr.length > 12 ? 14 : valStr.length > 8 ? 18 : 24;

  return (
    <div style={{
      background: 'var(--bg-card)',
      border: '1px solid var(--border)',
      borderRadius: 'var(--radius)',
      padding: '16px 18px',
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      boxShadow: 'var(--shadow-sm)',
      minWidth: 0,         // permite que el flex child se encoja
      overflow: 'hidden',
    }}>
      <div style={{
        width: 40, height: 40,
        borderRadius: 10,
        background: `${color}18`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        {icon}
      </div>
      <div style={{ minWidth: 0, flex: 1 }}>
        <div style={{
          fontSize,
          fontWeight: 700,
          color,
          lineHeight: 1.2,
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}>
          {value}
        </div>
        <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4, whiteSpace: 'nowrap' }}>
          {label}
        </div>
      </div>
    </div>
  );
}

function PeerStatusBadge({ isActive, lastHs }) {
  if (isActive) {
    return <span className="badge" style={{ background:'#d1fae5', color:'#065f46', border:'1px solid #a7f3d0' }}>● Activo</span>;
  }
  if (lastHs === null) {
    return <span className="badge" style={{ background:'#f3f4f6', color:'#6b7280', border:'1px solid #e5e7eb' }}>Sin conexión</span>;
  }
  return <span className="badge" style={{ background:'#fef3c7', color:'#92400e', border:'1px solid #fde68a' }}>◌ Inactivo</span>;
}

// ── Componente principal ─────────────────────────────────────

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  const [refreshing, setRefreshing] = useState(false);
  const intervalRef = useRef(null);

  const fetchData = useCallback(async (force = false) => {
    try {
      if (force) setRefreshing(true);
      const result = await fetchWireguardStatus(force);
      setData(result);
      setError(null);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    intervalRef.current = setInterval(() => fetchData(), REFRESH_INTERVAL);
    return () => clearInterval(intervalRef.current);
  }, [fetchData]);

  const handleRefresh = () => fetchData(true);

  // ── Loading ───────────────────────────────────────────────
  if (loading) {
    return (
      <div>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:32 }}>
          <h1 className="page-title" style={{ margin:0 }}>Dashboard VPN</h1>
        </div>
        <div className="loading">
          <div className="spinner" />
          <p>Conectando al servidor WireGuard vía SSH...</p>
        </div>
      </div>
    );
  }

  // ── Error ─────────────────────────────────────────────────
  if (error) {
    return (
      <div>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:32 }}>
          <h1 className="page-title" style={{ margin:0 }}>Dashboard VPN</h1>
          <button className="btn btn-primary" onClick={handleRefresh}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            Reintentar
          </button>
        </div>
        <div className="error">
          <strong>Error de conexión:</strong> {error}
          <br /><small style={{ opacity:0.7, marginTop:4, display:'block' }}>
            Verifica que el backend esté corriendo y el servidor sea accesible.
          </small>
        </div>
      </div>
    );
  }

  const { server, system, summary, peers } = data;

  return (
    <div>
      {/* ── Header ─────────────────────────────────────────── */}
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:32, flexWrap:'wrap', gap:12 }}>
        <div>
          <h1 className="page-title" style={{ margin:0, marginBottom:6 }}>Dashboard VPN</h1>
          {lastUpdated && (
            <p style={{ fontSize:13, color:'var(--text-muted)', margin:0 }}>
              Actualizado: {lastUpdated.toLocaleTimeString()} · Auto-refresco cada 15s
              {data.cached && <span style={{ marginLeft:8, opacity:0.6 }}>(caché)</span>}
            </p>
          )}
        </div>
        <button
          className="btn btn-primary"
          onClick={handleRefresh}
          disabled={refreshing}
          id="btn-refresh-dashboard"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
            style={{ animation: refreshing ? 'spin 1s linear infinite' : 'none' }}>
            <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/>
            <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
          </svg>
          {refreshing ? 'Actualizando...' : 'Actualizar'}
        </button>
      </div>

      {/* ── Server Status mini-bar ──────────────────────────── */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20,
        padding: '8px 16px', borderRadius: 8,
        background: server.active ? '#f0fdf4' : '#fef2f2',
        border: `1px solid ${server.active ? '#bbf7d0' : '#fecaca'}`,
      }}>
        <StatusDot active={server.active} />
        <span style={{ fontWeight: 700, fontSize: 15, color: server.active ? '#166534' : '#991b1b' }}>
          Servidor WireGuard — {server.active ? 'ACTIVO' : 'INACTIVO'}
        </span>
        <span style={{ marginLeft: 'auto', fontSize: 12, color: 'var(--text-muted)' }}>
          Interfaz: <code>{server.interface}</code>
        </span>
      </div>

      {/* ── Server Info Cards ────────────────────────────────── */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fit, minmax(180px, 1fr))', gap:16, marginBottom:24 }}>
        <StatCard
          label="IP del Servidor"
          value={server.host}
          color="#4f46e5"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>}
        />
        <StatCard
          label="Puerto WireGuard"
          value={server.listenPort ?? '51820'}
          color="#06b6d4"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" strokeWidth="2"><path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/><line x1="9" y1="14" x2="9.01" y2="14"/><line x1="12" y1="14" x2="12.01" y2="14"/><line x1="15" y1="14" x2="15.01" y2="14"/></svg>}
        />
        <StatCard
          label="Tiempo Activo"
          value={
            (system.uptime?.replace('up ', '') || 'N/A')
              .replace(' weeks', 'sem').replace(' week', 'sem')
              .replace(' days', 'd').replace(' day', 'd')
              .replace(' hours', 'h').replace(' hour', 'h')
              .replace(/, \d+ minutes.*/, '').replace(' minutes', 'min')
          }
          color="#10b981"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#10b981" strokeWidth="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>}
        />
        <StatCard
          label="Memoria Usada"
          value={system.memory || 'N/A'}
          color="#f59e0b"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" strokeWidth="2"><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M12 12h.01"/><path d="M7 12h.01"/><path d="M17 12h.01"/></svg>}
        />
      </div>

      {/* ── Peer Stats Cards ─────────────────────────────────── */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fit, minmax(180px, 1fr))', gap:16, marginBottom:24 }}>
        <StatCard
          label="Peers Activos"
          value={summary.activePeers}
          color="var(--success)"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#10b981" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/></svg>}
        />
        <StatCard
          label="Peers Inactivos"
          value={summary.inactivePeers}
          color="var(--warning)"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>}
        />
        <StatCard
          label="Total Peers"
          value={summary.totalPeers}
          color="var(--primary)"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>}
        />
        <StatCard
          label="Total Recibido ↓"
          value={formatBytes(summary.totalRxBytes)}
          color="#06b6d4"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" strokeWidth="2"><polyline points="8 17 12 21 16 17"/><line x1="12" y1="12" x2="12" y2="21"/><path d="M20.88 18.09A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.29"/></svg>}
        />
        <StatCard
          label="Total Enviado ↑"
          value={formatBytes(summary.totalTxBytes)}
          color="#8b5cf6"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" strokeWidth="2"><polyline points="16 7 12 3 8 7"/><line x1="12" y1="3" x2="12" y2="12"/><path d="M20.88 18.09A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.29"/></svg>}
        />

      </div>

      {/* ── Peers Table ──────────────────────────────────────── */}
      <div className="card">
        <div className="card-header">
          <h2>Peers WireGuard</h2>
          <span style={{ fontSize:13, color:'var(--text-muted)' }}>
            {summary.activePeers} activos de {summary.totalPeers}
          </span>
        </div>

        {peers.length === 0 ? (
          <div className="empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
            </svg>
            <p>No hay peers configurados en el servidor.</p>
          </div>
        ) : (
          <div className="table-container">
            <table className="table" id="tabla-peers-wireguard">
              <thead>
                <tr>
                  <th>#</th>
                  <th>IP Asignada</th>
                  <th>Estado</th>
                  <th>Último Handshake</th>
                  <th>Endpoint</th>
                  <th>↓ Recibido</th>
                  <th>↑ Enviado</th>
                </tr>
              </thead>
              <tbody>
                {peers.map((peer, idx) => (
                  <tr key={peer.pubKey} id={`peer-row-${idx + 1}`}>
                    <td style={{ color:'var(--text-muted)', fontWeight:600 }}>{idx + 1}</td>
                    <td>
                      <code style={{ fontSize:13, background:'#f3f4f6', padding:'2px 8px', borderRadius:6 }}>
                        {peer.allowedIps?.split('/')[0]}
                      </code>
                    </td>
                    <td>
                      <PeerStatusBadge isActive={peer.isActive} lastHs={peer.lastHandshake} />
                    </td>
                    <td style={{ fontSize:13, color: peer.isActive ? 'var(--success)' : 'var(--text-muted)' }}>
                      {peer.lastHandshakeAgo !== null
                        ? formatTimeAgo(peer.lastHandshakeAgo)
                        : <span style={{ opacity:0.5 }}>Nunca</span>
                      }
                    </td>
                    <td style={{ fontSize:12, fontFamily:'monospace', color:'var(--text-muted)' }}>
                      {peer.endpoint || <span style={{ opacity:0.4 }}>—</span>}
                    </td>
                    <td style={{ fontSize:13 }}>{formatBytes(peer.rxBytes)}</td>
                    <td style={{ fontSize:13 }}>{formatBytes(peer.txBytes)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ── Footer Info ──────────────────────────────────────── */}
      <div style={{ marginTop:16, fontSize:12, color:'var(--text-muted)', textAlign:'right' }}>
        Un peer se considera <strong>activo</strong> si su último handshake fue hace menos de 3 minutos.
      </div>
    </div>
  );
}
