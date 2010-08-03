--[[

   Pirate Hitman 2

   Corrupt Merchant wants you to destroy competition

   Author: nloewen

--]]

-- Localization, choosing a language if naev is translated for non-english-speaking locales.
lang = naev.lang()
if lang == "es" then
else -- Default to English
   -- Bar information
   bar_desc = "You see the shifty merchant who hired you previously. He looks somewhat anxious, perhaps he has more business to discuss."

   -- Mission details
   misn_title  = "Pirate Hitman 2"
   misn_reward = "Some easy money." -- Possibly some hard to get contraband once it is introduced
   misn_desc   = {}
   misn_desc[1] = "Take out some merchant competition in the %s system."
   misn_desc[2] = "Return to %s in the %s system for payment."

   -- Text
   title    = {}
   text     = {}
   title[1] = "Spaceport Bar"
   text[1]  = [[As you approach, the man turns to face you and his anxiousness seems to abate somewhat. As you take a seat he greets you, "Ah, so we meet again. My, shall we say... problem, has recurred." Leaning closer, he continues, "This will be somewhat bloodier than last time, but I'll pay you more for your trouble. Are you up for it?"]]
   text[2] = [[He nods approvingly. "It seems that the traders are rather stubborn, they didn't get the message last time and their presence is increasing." He lets out a brief sigh before continuing, "This simply won't do, it's bad for business. Perhaps if a few of their ships disappear, they'll take the hint." With the arrangement in place, he gets up. "I look forward to seeing you soon. Hopefully this will be the end of my problems."]]
   title[3] = "Mission Complete"
   text[3] = [[You glance around, looking for your acquaintance, but he has noticed you first, motioning for you to join him. As you approach the table, he smirks. "I hope the Empire didn't give you too much trouble." After a short pause, he continues, "The payment has been transferred. Much as I enjoy working with you, hopefully this is the last time I'll require your services."]]

   -- Messages
   msg      = {}
   msg[1]   = "MISSION SUCCESS! Return for payment."
end

function create ()
   targetsystem = system.get("Delta Pavonis") -- Find target system

   -- Spaceport bar stuff
   misn.setNPC( "Shifty Trader",  "shifty_merchant")
   misn.setDesc( bar_desc )
end


--[[
Mission entry point.
--]]
function accept ()
   -- Mission details:
   if not tk.yesno( title[1], string.format( text[1],
          targetsystem:name() ) ) then
      misn.finish()
   end
   misn.accept()

   -- Some variables for keeping track of the mission
   misn_done      = false
   attackedTraders = {}
   attackedTraders["__save"] = true
   deadTraders = 0
   misn_base, misn_base_sys = planet.cur()

   -- Set mission details
   misn.setTitle( string.format( misn_title, targetsystem:name()) )
   misn.setReward( string.format( misn_reward, credits) )
   misn.setDesc( string.format( misn_desc[1], targetsystem:name() ) )
   misn_marker = misn.markerAdd( targetsystem, "low" )

   -- Some flavour text
   tk.msg( title[1], string.format( text[2], targetsystem:name()) )

   -- Set hooks
   hook.enter("sys_enter")
end

-- Entering a system
function sys_enter ()
   cur_sys = system.get()
   -- Check to see if reaching target system
   if cur_sys == targetsystem then
      hook.pilot(nil, "attacked", "trader_attacked")
      hook.pilot(nil, "death", "trader_death")
   end
end

-- Attacked a trader
function trader_attacked (hook_pilot, hook_attacker, hook_arg)
   if misn_done then
      return
   end

   if hook_pilot:faction() == faction.get("Trader") and hook_attacker == pilot.player() then
      attackedTraders[#attackedTraders + 1] = hook_pilot
   end
end

-- An attacked Trader Jumped
function trader_death (hook_pilot, hook_arg)
   if misn_done then
      return
   end

   for i, array_pilot in ipairs(attackedTraders) do
      if array_pilot:exists() then
         if array_pilot == hook_pilot then
            deadTraders = deadTraders + 1
            if deadTraders >= 3 then
               attack_finished()
            end
         end
      end
   end
end

-- attack finished
function attack_finished()
   misn_done = true
   player.msg( msg[1] )
   misn.setDesc( string.format( misn_desc[2], misn_base:name(), misn_base_sys:name() ) )
   misn.markerRm( misn_marker )
   misn_marker = misn.markerAdd( misn_base_sys, "low" )
   hook.land("landed")
end

-- landed
function landed()
   if planet.get() == misn_base then
      tk.msg(title[3], text[3])
      player.pay(25000)
      player.modFaction("Pirate",5)
      misn.finish(true)
   end
end
