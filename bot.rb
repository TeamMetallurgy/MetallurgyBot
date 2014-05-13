require 'cinch'
require 'cinch/plugins/identify'
require 'yaml/store'

class Request < Struct.new(:nick, :name, :channel)

end
store = YAML::Store.new("data.yml")

$admin_room = store.transaction { store.fetch(:admin_room, '#TeamMetallurgy') }
$room = store.transaction { store.fetch(:room, :'#Metallurgy') }
$bot_name = store.transaction { store.fetch(:bot_name, 'MetallurgyBot') }
$server = store.transaction { store.fetch(:server_name, 'localhost') }

$ns_name = store.transaction { store.fetch(:ns_name, "") }
$ns_password = store.transaction { store.fetch(:ns_password, "") }

$requests = {}

def sync_datastore(store)
  store.transaction do
    store[:requests] = $requests
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = $bot_name
    c.realname = $bot_name
    c.server = $server
    c.channels = [$room.to_s, $admin_room.to_s]

    unless $ns_name.empty? && $ns_password.empty?
      c.plugins.plugins = [Cinch::Plugins::Identify]
      c.plugins.options[Cinch::Plugins::Identify] = {
          :username => $ns_name,
          :password => $ns_password,
          :type => :nickserv,
      }
    end
  end


  on :message, /^!request (.+)/ do |m, minecraftname|
    $requests[minecraftname] = Request.new(m.user.nick, minecraftname, m.channel.name)

    store.transaction do
      request = store[:requests] || {}
      request.merge! $requests
    end

    Channel($admin_room).send "#{m.user.nick} has request to be white-listed with the name #{minecraftname}."
    Channel($admin_room).send "To accept type: !accept #{minecraftname}"
    Channel($admin_room).send "To deny type: !deny #{minecraftname}"
  end

  on :message, /^!accept (.+)/ do |m, minecraftname|
    if Channel($admin_room).opped?(m.user)
      if $requests.has_key?(minecraftname)
        request = $requests.delete(minecraftname)

        sync_datastore(store)

        Channel(request.channel).send "#{request.nick} has been added to the white-list by #{m.user.nick}."
      else
        m.reply "Request not found for name \"#{minecraftname}\"."
      end
    end
  end

  on :message, /^!deny (.+)/ do |m, minecraftname|
    if Channel($admin_room).opped?(m.user)
      if $requests.has_key?(minecraftname)
        current_request = $requests.delete(minecraftname)

        sync_datastore(store)

        Channel(current_request.channel).send "#{current_request.nick} has been denied to be white-listed by #{m.user.nick}."
      else
        m.reply "Request not found for name \"#{minecraftname}\"."
      end
    end
  end

  on :message, /^!request-list/ do |m|
    if Channel($admin_room).opped?(m.user)
      requests = store.transaction { store[:requests] }

      if requests.nil? || requests.empty?
        m.user.msg 'No pending white-list applications.'
      else
        m.user.msg "#{requests.size} Pending white-list applications:"
        requests.each_with_index { |(name, request), index| m.user.msg "#{index}: #{request.name}" }
      end
    end
  end

  on :message, /^!get-whitelist/ do |m|
    if Channel($admin_room).opped?(m.user)
    end
  end
end

bot.start
