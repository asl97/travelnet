local get_formspec = function(owner, pos)
    return "size[2,2;]button[0,1;1,1;save;save]field[0,0;2,1;owner;;"..owner.."]textarea[-1,-1;0,0;pos;;"..minetest.pos_to_string(pos).."]"
end

travelnet.get_station_data = function(owner, station_network, station_name)
    if not travelnet.targets[ owner ] then
        travelnet.targets[ owner ] = {}
    end
    if not travelnet.targets[ owner ][ station_network ] then
        travelnet.targets[ owner ][ station_network ] = {}
    end
    return travelnet.targets[ owner ][ station_network ][ station_name ]
end

travelnet.transfer_owner = function(old, new, station_network, station_name)
    local old = old:lower()
    local new = new:lower()
    local data = travelnet.get_station_data(old, station_network, station_name)
    if data == nil then
        minetest.chat_send_player(old, "Station '"..station_name.."' isn't owned by you");
        return
    end

    local meta = minetest:get_meta(data.pos)
    if not meta:get_string("owner") == old then
        minetest.chat_send_player(old, "Station '"..station_name.."' isn't owned by you");
        return
    end

    if old == new then
        minetest.chat_send_player(old, "Old and New owner is the same");
        return
    end

    local data = travelnet.get_station_data(new, station_network, station_name)
    if data == nil then
        travelnet.targets[ new ][ station_network ][ station_name ] = travelnet.targets[ old ][ station_network ][ station_name ]
        travelnet.targets[ old ][ station_network ][ station_name ] = nil

        minetest.chat_send_player(old, "Station '"..station_name.."' has been transfer to "..new);
        minetest.chat_send_player(new, "Station '"..station_name.."' has been transfer you by "..old);
        return true
    else
        minetest.chat_send_player(old, new.." already has a station named '"..station_name.."'");
   end
end

minetest.register_tool("travelnet:meta_owner_editor", {
    description = "Click on nodes to edit owner",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing then
            local meta = minetest.get_meta(pointed_thing.under)
            local owner = meta:get_string("owner")
            if owner then
                minetest.show_formspec(user:get_player_name(), "travelnet_owner_editor", get_formspec(owner, pointed_thing.under))
            end
        end
   end
})

minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "travelnet_owner_editor" then
            if fields["save"] then
                local pos = minetest.string_to_pos(fields["pos"])
                if pos then
                    local meta = minetest.get_meta(pos)
                    if travelnet.transfer_owner(player:get_player_name(), fields["owner"], meta:get_string( "station_network" ), meta:get_string( "station_name" )) then
                        meta:set_string("owner", fields["owner"])
                    end
                end
            end
        end
    end
)
