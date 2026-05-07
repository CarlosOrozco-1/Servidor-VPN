import { useState, useEffect, useRef, useCallback } from 'react';
import { fetchTrafficRates, fetchPacketCapture, formatBytes } from '../services/wireguardService';
import { getUsuarios } from '../services/api';

const TRAFFIC_INTERVAL = 5000;
const PACKETS_INTERVAL = 6000;
const MAX_LOG = 150;

/* ── Helpers ──────────────────────────────────────────────── */
function formatRate(bps) {
  if (!bps) return null;
  if (bps >= 1048576) return { val: (bps / 1048576).toFixed(2), unit: 'MB/s', color: '#8b5cf6' };
  if (bps >= 1024)    return { val: (bps / 1024).toFixed(1),    unit: 'KB/s', color: '#06b6d4' };
  return { val: bps, unit: 'B/s', color: '#10b981' };
}

function RateBadge({ bps }) {
  const r = formatRate(bps);
  if (!r) return <span style={{ color: '#475569', fontSize: 12 }}>—</span>;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'baseline', gap: 2,
      fontVariantNumeric: 'tabular-nums',
    }}>
      <span style={{ fontWeight: 700, color: r.color, fontSize: 15 }}>{r.val}</span>
      <span style={{ color: r.color, fontSize: 11, opacity: 0.8 }}>{r.unit}</span>
    </span>
  );
}

function Countdown({ interval, tick }) {
  const [s, setS] = useState(Math.ceil(interval / 1000));
  useEffect(() => {
    setS(Math.ceil(interval / 1000));
    const t = setInterval(() => setS(p => Math.max(0, p - 1)), 1000);
    return () => clearInterval(t);
  }, [tick, interval]);
  return <span>{s}s</span>;
}

function Avatar({ name }) {
  const initials = name
    ? name.trim().split(' ').slice(0, 2).map(w => w[0].toUpperCase()).join('')
    : '?';
  const hue = name ? [...name].reduce((a, c) => a + c.charCodeAt(0), 0) % 360 : 200;
  return (
    <div style={{
      width: 32, height: 32, borderRadius: '50%', flexShrink: 0,
      background: `hsl(${hue},60%,50%)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 12, fontWeight: 700, color: '#fff',
    }}>{initials}</div>
  );
}

/* ── Stepper Tab ──────────────────────────────────────────── */
function StepTab({ steps, active, onChange }) {
  return (
    <div style={{
      display: 'flex', gap: 0,
      background: '#f1f5f9', borderRadius: 12,
      padding: 4, marginBottom: 24,
      position: 'relative',
    }}>
      {steps.map((s, i) => (
        <button
          key={i}
          id={`step-tab-${i}`}
          onClick={() => onChange(i)}
          style={{
            flex: 1, border: 'none', cursor: 'pointer',
            padding: '10px 20px', borderRadius: 10,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            fontSize: 14, fontWeight: 600, transition: 'all 0.2s',
            background: active === i
              ? '#fff'
              : 'transparent',
            color: active === i ? '#4f46e5' : '#64748b',
            boxShadow: active === i ? '0 1px 4px rgba(0,0,0,0.12)' : 'none',
          }}
        >
          <span style={{ fontSize: 18 }}>{s.icon}</span>
          {s.label}
          {s.badge != null && (
            <span style={{
              background: active === i ? '#4f46e5' : '#cbd5e1',
              color: active === i ? '#fff' : '#475569',
              borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 700,
            }}>{s.badge}</span>
          )}
        </button>
      ))}
    </div>
  );
}

/* ── Main Component ──────────────────────────────────────── */
export default function MonitoreoTiempoReal() {
  const [step, setStep]               = useState(0);
  const [traffic, setTraffic]         = useState(null);
  const [packets, setPackets]         = useState([]);
  const [totalCaptured, setTotalCaptured] = useState(0);
  const [packetStats, setPacketStats] = useState('');
  const [packetIface, setPktIface]    = useState('ens3');
  const [usuarios, setUsuarios]       = useState([]);
  const [paused, setPaused]           = useState(false);
  const [trafficErr, setTrafficErr]   = useState(null);
  const [packetErr, setPacketErr]     = useState(null);
  const [loadingT, setLoadingT]       = useState(true);
  const [loadingP, setLoadingP]       = useState(true);
  const [lastT, setLastT]             = useState(Date.now());
  const [lastP, setLastP]             = useState(Date.now());
  const logRef = useRef(null);

  // IP → usuario lookup
  const userByIp = useCallback((ip) => {
    const clean = ip?.split('/')[0];
    return usuarios.find(u => u.ip_asignada === clean);
  }, [usuarios]);

  // Fetch usuarios once
  useEffect(() => {
    getUsuarios().then(u => setUsuarios(Array.isArray(u) ? u : [])).catch(() => {});
  }, []);

  const pollTraffic = useCallback(async () => {
    try {
      const r = await fetchTrafficRates();
      if (r.ok) { setTraffic(r); setTrafficErr(null); }
      else setTrafficErr(r.error);
    } catch (e) { setTrafficErr(e.message); }
    finally { setLoadingT(false); setLastT(Date.now()); }
  }, []);

  const pollPackets = useCallback(async () => {
    try {
      const r = await fetchPacketCapture();
      if (r.ok && !r.busy && r.packets?.length > 0) {
        setPackets(prev => [...r.packets, ...prev].slice(0, MAX_LOG));
        setTotalCaptured(prev => prev + r.packets.length);
        setPacketStats(r.stats || '');
        setPktIface(r.iface || 'ens3');
        setPacketErr(null);
      } else if (!r.ok) setPacketErr(r.error);
    } catch (e) { setPacketErr(e.message); }
    finally { setLoadingP(false); setLastP(Date.now()); }
  }, []);

  useEffect(() => { pollTraffic(); pollPackets(); }, []);

  useEffect(() => {
    if (paused) return;
    const tT = setInterval(pollTraffic, TRAFFIC_INTERVAL);
    const tP = setInterval(pollPackets, PACKETS_INTERVAL);
    return () => { clearInterval(tT); clearInterval(tP); };
  }, [paused, pollTraffic, pollPackets]);

  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = 0;
  }, [packets]);

  const activeCount  = traffic?.rates?.filter(p => p.isActive).length ?? 0;
  const hasTraffic   = traffic?.rates?.some(p => p.rxRate > 0 || p.txRate > 0);

  const steps = [
    { icon: '📊', label: 'Tráfico en Vivo', badge: activeCount },
    { icon: '📡', label: 'Captura de Paquetes', badge: packets.length || null },
  ];

  return (
    <div style={{ fontFamily: 'inherit' }}>

      {/* ── Header ───────────────────────────────────────────── */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
        marginBottom: 24, flexWrap: 'wrap', gap: 12,
      }}>
        <div>
          <h1 className="page-title" style={{ margin: 0, marginBottom: 4 }}>
            Monitor en Tiempo Real
          </h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 13, color: 'var(--text-muted)' }}>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 5,
              padding: '3px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600,
              background: paused ? '#fee2e2' : '#dcfce7',
              color: paused ? '#991b1b' : '#166534',
            }}>
              <span style={{
                width: 7, height: 7, borderRadius: '50%',
                background: paused ? '#ef4444' : '#22c55e',
                animation: paused ? 'none' : 'livePulse 2s infinite',
              }} />
              {paused ? 'Pausado' : 'En vivo'}
            </span>
            {!paused && (
              <span style={{ opacity: 0.7 }}>
                {step === 0
                  ? <><Countdown interval={TRAFFIC_INTERVAL} tick={lastT} /> para actualizar tráfico</>
                  : <><Countdown interval={PACKETS_INTERVAL} tick={lastP} /> para nueva captura</>
                }
              </span>
            )}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn" onClick={() => setPaused(p => !p)} id="btn-toggle-monitor"
            style={{ borderColor: paused ? '#4f46e5' : undefined, color: paused ? '#4f46e5' : undefined }}>
            {paused
              ? <><span>▶</span> Reanudar</>
              : <><span>⏸</span> Pausar</>}
          </button>
          <button className="btn btn-primary" id="btn-refresh-monitor"
            onClick={() => { pollTraffic(); pollPackets(); }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/>
              <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
            </svg>
            Actualizar
          </button>
        </div>
      </div>

      {/* ── Stepper ──────────────────────────────────────────── */}
      <StepTab steps={steps} active={step} onChange={setStep} />

      {/* ── Panel 0: Tráfico ─────────────────────────────────── */}
      {step === 0 && (
        <div className="card" style={{ margin: 0 }}>
          <div style={{ marginBottom: 20 }}>
            <h2 style={{ margin: 0, fontSize: 16, marginBottom: 4 }}>Tráfico por Peer</h2>
            <p style={{ margin: 0, fontSize: 12, color: 'var(--text-muted)' }}>
              Basado en <code>wg show {'{iface}'} transfer</code> — diferencia entre lecturas cada 5s
              {hasTraffic && <span style={{ color: '#22c55e', marginLeft: 8 }}>● Con actividad</span>}
            </p>
          </div>

          {loadingT ? (
            <div className="loading"><div className="spinner"/><p>Calculando tasas...</p></div>
          ) : trafficErr ? (
            <div className="error">{trafficErr}</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {(traffic?.rates || []).map((peer, i) => {
                const ip      = peer.allowedIps?.split('/')[0] || '—';
                const usuario = userByIp(peer.allowedIps);
                const nombre  = usuario?.nombre || null;
                const so      = usuario?.sistema_operativo || null;
                const soIcons = { windows: '🪟', linux: '🐧', android: '📱' };

                return (
                  <div key={peer.pubKey} id={`peer-traffic-${i + 1}`} style={{
                    display: 'grid',
                    gridTemplateColumns: '40px 1fr 110px 110px 90px 90px',
                    alignItems: 'center',
                    gap: 12,
                    padding: '12px 16px',
                    borderRadius: 10,
                    border: '1px solid var(--border)',
                    background: peer.isActive ? '#f0fdf4' : '#fafafa',
                    transition: 'background 0.2s',
                  }}>
                    {/* Avatar */}
                    <Avatar name={nombre || ip} />

                    {/* Nombre + IP */}
                    <div style={{ minWidth: 0 }}>
                      <div style={{
                        fontWeight: 600, fontSize: 14,
                        color: peer.isActive ? 'var(--text-main)' : 'var(--text-muted)',
                        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                      }}>
                        {nombre || <span style={{ opacity: 0.5, fontStyle: 'italic' }}>Sin usuario</span>}
                        {so && <span style={{ marginLeft: 6 }}>{soIcons[so] || '💻'}</span>}
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 2 }}>
                        <code style={{
                          fontSize: 11, background: peer.isActive ? '#dcfce7' : '#f1f5f9',
                          color: peer.isActive ? '#166534' : '#64748b',
                          padding: '1px 6px', borderRadius: 4,
                        }}>{ip}</code>
                        {peer.isActive && (
                          <span style={{
                            fontSize: 10, fontWeight: 700, color: '#16a34a',
                            background: '#dcfce7', padding: '1px 6px', borderRadius: 10,
                          }}>ACTIVO</span>
                        )}
                      </div>
                    </div>

                    {/* RX rate */}
                    <div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 2 }}>↓ Recibe</div>
                      <RateBadge bps={peer.rxRate} />
                    </div>

                    {/* TX rate */}
                    <div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 2 }}>↑ Envía</div>
                      <RateBadge bps={peer.txRate} />
                    </div>

                    {/* Total RX */}
                    <div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 2 }}>Total ↓</div>
                      <div style={{ fontSize: 13, color: 'var(--text-main)' }}>{formatBytes(peer.rxBytes)}</div>
                    </div>

                    {/* Total TX */}
                    <div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 2 }}>Total ↑</div>
                      <div style={{ fontSize: 13, color: 'var(--text-main)' }}>{formatBytes(peer.txBytes)}</div>
                    </div>
                  </div>
                );
              })}

              {(!traffic?.rates || traffic.rates.length === 0) && (
                <div className="empty">
                  <p>No hay datos de peers aún.</p>
                </div>
              )}
            </div>
          )}

          <p style={{ marginTop: 16, fontSize: 11, color: 'var(--text-muted)', textAlign: 'right' }}>
            La primera lectura siempre es 0 B/s — necesita dos snapshots para calcular el delta.
          </p>
        </div>
      )}

      {/* ── Panel 1: Captura de Paquetes ─────────────────────── */}
      {step === 1 && (
        <div className="card" style={{ margin: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
            <div>
              <h2 style={{ margin: 0, fontSize: 16, marginBottom: 4 }}>Captura de Paquetes UDP</h2>
              <p style={{ margin: 0, fontSize: 12, color: 'var(--text-muted)' }}>
                <code>tcpdump -i {packetIface} udp port 51820</code>
                {' · '}timeout 4s por ciclo
              </p>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              {packets.length > 0 && (
                <button className="btn btn-sm" id="btn-clear-packets" onClick={() => setPackets([])}
                  style={{ fontSize: 12 }}>
                  Limpiar log
                </button>
              )}
            </div>
          </div>

          {loadingP ? (
            <div className="loading"><div className="spinner"/><p>Iniciando captura...</p></div>
          ) : packetErr ? (
            <div className="error">{packetErr}</div>
          ) : (
            <>
              {/* Stats Cards */}
              <div style={{
                display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 16,
              }}>
                <div style={{
                  background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: 12, padding: '16px',
                  display: 'flex', alignItems: 'center', gap: 16,
                }}>
                  <div style={{ width: 44, height: 44, borderRadius: 10, background: '#e0f2fe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0ea5e9" strokeWidth="2"><path d="M4 22h14a2 2 0 0 0 2-2V7.5L14.5 2H6a2 2 0 0 0-2 2v4"/><polyline points="14 2 14 8 20 8"/><path d="M2 15h10"/><path d="m9 18 3-3-3-3"/></svg>
                  </div>
                  <div>
                    <div style={{ fontSize: 24, fontWeight: 700, color: '#0ea5e9', lineHeight: 1 }}>{totalCaptured}</div>
                    <div style={{ fontSize: 13, color: '#64748b', marginTop: 4 }}>Total Capturados</div>
                  </div>
                </div>

                <div style={{
                  background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: 12, padding: '16px',
                  display: 'flex', alignItems: 'center', gap: 16,
                }}>
                  <div style={{ width: 44, height: 44, borderRadius: 10, background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                  </div>
                  <div>
                    <div style={{ fontSize: 24, fontWeight: 700, color: '#475569', lineHeight: 1 }}>{packets.length} / {MAX_LOG}</div>
                    <div style={{ fontSize: 13, color: '#64748b', marginTop: 4 }}>Visibles en Log</div>
                  </div>
                </div>
              </div>

              {packetStats && (
                <div style={{
                  padding: '8px 14px', borderRadius: 8, marginBottom: 16,
                  background: '#f1f5f9', fontSize: 12, color: '#475569',
                  fontFamily: 'monospace',
                }}>{packetStats}</div>
              )}

              {/* Terminal */}
              <div ref={logRef} id="packet-log" style={{
                background: '#0f172a',
                borderRadius: 12,
                padding: '16px',
                fontFamily: "'JetBrains Mono','Fira Code','Courier New',monospace",
                fontSize: 12,
                lineHeight: 1.8,
                overflowY: 'auto',
                maxHeight: 480,
                minHeight: 220,
                color: '#e2e8f0',
                border: '1px solid #1e293b',
              }}>
                {/* Terminal title bar */}
                <div style={{
                  display: 'flex', gap: 6, marginBottom: 12, alignItems: 'center',
                }}>
                  <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#ef4444', display: 'inline-block' }} />
                  <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#f59e0b', display: 'inline-block' }} />
                  <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#22c55e', display: 'inline-block' }} />
                  <span style={{ marginLeft: 8, fontSize: 11, color: '#475569' }}>
                    tcpdump -i {packetIface} udp port 51820 -n
                  </span>
                </div>

                {packets.length === 0 ? (
                  <div style={{ color: '#475569', textAlign: 'center', paddingTop: 60 }}>
                    <div style={{ fontSize: 28, marginBottom: 8 }}>📭</div>
                    <div>Sin tráfico UDP en puerto 51820</div>
                    <div style={{ fontSize: 11, marginTop: 6, opacity: 0.6 }}>
                      Los paquetes aparecen cuando hay actividad VPN
                    </div>
                  </div>
                ) : (
                  packets.map((pkt) => (
                    <div key={pkt.id} style={{
                      display: 'grid',
                      gridTemplateColumns: '90px 1fr auto 1fr',
                      gap: 8,
                      borderBottom: '1px solid #1e293b',
                      paddingBottom: 2, marginBottom: 2,
                      alignItems: 'center',
                    }}>
                      <span style={{ color: '#334155', fontSize: 11 }}>{pkt.time}</span>
                      <span style={{ color: '#38bdf8' }}>{pkt.src || '—'}</span>
                      <span style={{ color: '#475569', fontSize: 10 }}>→</span>
                      <span style={{ color: '#34d399' }}>{pkt.dst || pkt.raw}</span>
                    </div>
                  ))
                )}
              </div>
            </>
          )}

          <p style={{ marginTop: 12, fontSize: 11, color: 'var(--text-muted)', textAlign: 'right' }}>
            Equivalente a <code>tcpdump</code> · máx {MAX_LOG} líneas · se acumulan entre ciclos
          </p>
        </div>
      )}

      {/* ── Info footer ──────────────────────────────────────── */}
      <div style={{
        marginTop: 20, padding: '12px 16px', borderRadius: 10,
        background: '#eff6ff', border: '1px solid #bfdbfe',
        fontSize: 12, color: '#1e40af',
        display: 'flex', gap: 8, alignItems: 'flex-start',
      }}>
        <span style={{ fontSize: 16 }}>ℹ️</span>
        <span>
          <strong>Tráfico:</strong> diferencia entre snapshots de <code>wg show transfer</code> (equiv. iftop) ·{' '}
          <strong>Paquetes:</strong> <code>tcpdump</code> vía SSH con timeout 4s · Peers sin tráfico muestran 0 B/s hasta activarse.
        </span>
      </div>

      <style>{`
        @keyframes livePulse {
          0%, 100% { opacity: 1; }
          50%       { opacity: 0.3; }
        }
      `}</style>
    </div>
  );
}
