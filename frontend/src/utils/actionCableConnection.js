import ActionCable from 'actioncable'

// Singleton para mantener la conexión ActionCable fuera del ciclo de vida de React
let globalConsumer = null
let globalSubscription = null
let connectionCallbacks = {
  onConnected: null,
  onDisconnected: null,
  onRejected: null,
  onReceived: null,
}

export const createActionCableConnection = (token, callbacks) => {
  // Si ya existe una conexión activa, reutilizarla
  if (globalConsumer && globalSubscription) {
    connectionCallbacks = { ...connectionCallbacks, ...callbacks }
    if (callbacks.onConnected) {
      callbacks.onConnected(globalConsumer, globalSubscription)
    }
    return { consumer: globalConsumer, subscription: globalSubscription }
  }

  // Guardar callbacks
  connectionCallbacks = { ...callbacks }

  const wsUrl = `ws://localhost:3000/cable?token=${token}`

  globalConsumer = ActionCable.createConsumer(wsUrl)

  globalSubscription = globalConsumer.subscriptions.create(
    { channel: 'NotificationsChannel' },
    {
      connected() {
        if (connectionCallbacks.onConnected) {
          connectionCallbacks.onConnected(globalConsumer, globalSubscription)
        }
      },
      disconnected() {
        if (connectionCallbacks.onDisconnected) {
          connectionCallbacks.onDisconnected()
        }
      },
      rejected(reason) {
        console.error('Error de conexión ActionCable:', reason)
        if (connectionCallbacks.onRejected) {
          connectionCallbacks.onRejected(reason)
        }
      },
      received(data) {
        if (connectionCallbacks.onReceived) {
          connectionCallbacks.onReceived(data)
        }
      },
    }
  )

  return { consumer: globalConsumer, subscription: globalSubscription }
}

export const disconnectActionCable = () => {
  if (globalSubscription) {
    globalSubscription.unsubscribe()
    globalSubscription = null
  }

  if (globalConsumer) {
    globalConsumer.disconnect()
    globalConsumer = null
  }

  connectionCallbacks = {
    onConnected: null,
    onDisconnected: null,
    onRejected: null,
    onReceived: null,
  }
}

export const updateCallbacks = (callbacks) => {
  connectionCallbacks = { ...connectionCallbacks, ...callbacks }
}
