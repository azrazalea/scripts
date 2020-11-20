-- fixes some equipment corruption issues (bug 11014)

--[====[

fix/corrupt-equipment
=====================

Fixes some corruption that can occur in equipment lists, as in :bug:`11014`.

]====]

local utils = require("utils")

function fix_vector(vec, valid_items, message)
  local raw_vec = df.reinterpret_cast("ptr-vector", vec)
  for i = #vec - 1, 0, -1 do
    if not valid_items[utils.addressof(raw_vec[i])] then
      dfhack.printerr(string.format("%s (index %i)", message, i))
      vec:erase(i)
    end
  end
end

function fix_equipment ()
  local valid_items = {}
  for _, item in ipairs(df.item.get_vector()) do
    valid_items[utils.addressof(item)] = true
  end

  local categories =
    {{"FLASK", df.item_flaskst},
     {"WEAPON", df.item_weaponst},
     {"ARMOR", df.item_armorst},
     {"SHOES", df.item_shoesst},
     {"SHIELD", df.item_shieldst},
     {"HELM", df.item_helmst},
     {"GLOVES", df.item_glovesst},
     {"AMMO", df.item_ammost},
     {"PANTS", df.item_pantsst},
     {"BACKPACK", df.item_backpackst},
     {"QUIVER", df.item_quiverst}}

  for i, element in ipairs (categories) do
    fix_vector(df.global.ui.equipment.items_unmanifested[element[1]], valid_items,
      "Removing corrupted unmanifested " .. element[1])
    fix_vector(df.global.ui.equipment.items_unassigned[element[1]], valid_items,
      "Removing corrupted unassigned " .. element[1])
    fix_vector(df.global.ui.equipment.items_assigned[element[1]], valid_items,
      "Removing corrupted assigned " .. element[1])
  end

  for i, squad in ipairs (df.global.world.squads.all) do
    if squad.entity_id == df.global.ui.group_id then
      local squad_name = dfhack.TranslateName (squad.name, true)
      if squad.alias ~= "" then
        squad_name = squad.alias
      end

--      dfhack.println (squad_name, i)

      for k, position in ipairs (squad.positions) do
        for l, item_id in ipairs (position.assigned_items) do
          local legal_type_found = false
          local item = df.item.find (item_id)

          if not item then
            dfhack.printerr ("Nonexistent item assigned to squad member " .. tostring (k) .. " of squad " .. squad_name ..
                             ". Detection only. No action performed.")

          else
            for m, element in ipairs (categories) do
              if item._type == element [2] then
                legal_type_found = true
                break
              end
            end

            if not legal_type_found then
              dfhack.printerr ("Item " .. tostring (l) .. " assigned to squad member " .. tostring (k) .. " of squad " .. squad_name ..
                               " is of unexpected type " .. tostring (item._type) ..  ". Detection only. No action performed.")
            end
          end
        end
      end
    end
  end
end

fix_equipment ()
