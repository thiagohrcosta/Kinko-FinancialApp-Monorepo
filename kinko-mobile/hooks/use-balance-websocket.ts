import { useEffect, useRef, useCallback } from 'react';

type BalanceUpdateCallback = (data: {
  type: string;
  account_uuid: string;
  amount_cents: number;
  timestamp: string;
}) => void;

export function useBalanceWebSocket(
  token: string | null,
  onBalanceUpdate?: BalanceUpdateCallback
) {
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const onBalanceUpdateRef = useRef<BalanceUpdateCallback | undefined>(onBalanceUpdate);
  const shouldReconnectRef = useRef(true);
  const maxReconnectAttempts = 5;

  useEffect(() => {
    onBalanceUpdateRef.current = onBalanceUpdate;
  }, [onBalanceUpdate]);

  const connect = useCallback(() => {
    if (!token) {
      console.log('No token available, skipping WebSocket connection');
      return;
    }

    // Avoid parallel sockets for the same screen/session.
    if (wsRef.current && (wsRef.current.readyState === WebSocket.CONNECTING || wsRef.current.readyState === WebSocket.OPEN)) {
      return;
    }

    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }

    try {
      const protocol = process.env.EXPO_PUBLIC_API_URL?.startsWith('https') ? 'wss' : 'ws';
      const host = process.env.EXPO_PUBLIC_API_URL?.replace(/^https?:\/\//, '').replace(/\/$/, '') || 'localhost:3000';
      const wsUrl = `${protocol}://${host}/cable?token=${encodeURIComponent(token)}`;

      console.log('🔌 Connecting to WebSocket:', wsUrl);

      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        if (wsRef.current !== ws) return;

        console.log('✅ WebSocket connected');
        reconnectAttemptsRef.current = 0;

        // Enviar subscription message
        const subscriptionMessage = {
          command: 'subscribe',
          identifier: JSON.stringify({
            channel: 'NotificationsChannel',
            token: token
          })
        };
        ws.send(JSON.stringify(subscriptionMessage));
      };

      ws.onmessage = (event) => {
        if (wsRef.current !== ws) return;

        try {
          const message = JSON.parse(event.data);

          // ActionCable envolve as mensagens em um objeto com type: "message"
          if (message.type === 'message' && message.message) {
            console.log('📨 Received WebSocket message:', message.message);
            onBalanceUpdateRef.current?.(message.message);
          }
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };

      ws.onerror = () => {
        if (wsRef.current !== ws) return;
        console.log('❌ WebSocket transport error');
      };

      ws.onclose = (event) => {
        if (wsRef.current === ws) {
          wsRef.current = null;
        }

        console.log('🔌 WebSocket disconnected');

        if (!shouldReconnectRef.current) {
          return;
        }

        // Tentar reconectar com backoff exponencial
        if (reconnectAttemptsRef.current < maxReconnectAttempts) {
          const delayMs = Math.min(1000 * Math.pow(2, reconnectAttemptsRef.current), 10000);
          console.log(`⏳ Reconnecting in ${delayMs}ms...`);

          reconnectTimeoutRef.current = setTimeout(() => {
            reconnectAttemptsRef.current++;
            connect();
          }, delayMs);
        } else {
          console.log('❌ Max reconnection attempts reached');
        }
      };
    } catch (error) {
      console.error('Failed to create WebSocket:', error);
    }
  }, [token]);

  useEffect(() => {
    shouldReconnectRef.current = true;
    connect();

    return () => {
      shouldReconnectRef.current = false;

      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
        reconnectTimeoutRef.current = null;
      }

      if (wsRef.current) {
        wsRef.current.close();
        wsRef.current = null;
      }
    };
  }, [connect]);

  return wsRef.current;
}
