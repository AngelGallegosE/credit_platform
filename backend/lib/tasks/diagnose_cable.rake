namespace :cable do
  desc "Diagnosticar conexiones de ActionCable"
  task diagnose: :environment do
    puts "\n" + "=" * 60
    puts "DIAGNÓSTICO DE ACTIONCABLE"
    puts "=" * 60 + "\n"

    # Verificar conexiones activas
    puts "=== CONEXIONES ACTIVAS ==="
    total = ActionCable.server.connections.count
    puts "Total: #{total}\n"

    if total.zero?
      puts "⚠️  No hay conexiones activas en este momento."
      puts "   Asegúrate de que el frontend esté conectado al WebSocket.\n"
    else
      ActionCable.server.connections.each_with_index do |conn, idx|
        user = conn.current_user
        puts "[#{idx + 1}] Usuario: #{user&.id} (#{user&.email})"
        puts "    Identificador: #{conn.connection_identifier}"

        if conn.subscriptions.empty?
          puts "    ⚠️  No tiene suscripciones activas"
        else
          conn.subscriptions.each do |sub|
            puts "    Canal: #{sub.class.name}"
            puts "    Identificador del canal: #{sub.channel_identifier}"

            # Intentar obtener los streams de diferentes maneras
            streams = sub.instance_variable_get(:@streams) || {}
            stream_ids = sub.instance_variable_get(:@stream_ids) || []
            stream_identifier = sub.instance_variable_get(:@stream_identifier)

            puts "    Streams (@streams): #{streams.keys.inspect}" unless streams.empty?
            puts "    Stream IDs (@stream_ids): #{stream_ids.inspect}" unless stream_ids.empty?
            puts "    Stream identifier: #{stream_identifier.inspect}" if stream_identifier

            # Verificar si tiene stream de notificaciones
            has_notification_stream = false
            if streams.any? { |k, _| k.to_s.start_with?("notifications:") }
              has_notification_stream = true
            elsif stream_ids.any? { |id| id.to_s.start_with?("notifications:") }
              has_notification_stream = true
            elsif stream_identifier&.to_s&.start_with?("notifications:")
              has_notification_stream = true
            end

            if has_notification_stream
              puts "    ✅ Tiene stream de notificaciones"
            else
              puts "    ❌ NO tiene stream de notificaciones"
            end
          end
        end
        puts
      end
    end

    # Verificar usuarios específicos
    puts "=== VERIFICACIÓN DE USUARIOS ==="
    [ 1, 2, 3 ].each do |user_id|
      connected = ActionCable.server.connections.any? { |c| c.current_user&.id == user_id }
      puts "Usuario #{user_id} conectado: #{connected ? '✅' : '❌'}"
    end
    puts

    # Probar broadcast a diferentes usuarios
    puts "=== PROBANDO BROADCAST ==="
    [ 1, 2, 3 ].each do |user_id|
      stream_name = "notifications:#{user_id}"
      test_message = {
        type: "test",
        message: "Prueba desde rake task - #{Time.now}",
        user_id: user_id
      }
      ActionCable.server.broadcast(stream_name, test_message)
      puts "✅ Broadcast enviado a #{stream_name}"
    end
    puts

    puts "=" * 60
    puts "FIN DEL DIAGNÓSTICO"
    puts "=" * 60 + "\n"
  end
end
