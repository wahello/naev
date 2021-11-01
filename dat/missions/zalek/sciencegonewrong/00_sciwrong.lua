--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The one with the Shopping">
  <flags>
   <unique />
  </flags>
  <avail>
   <priority>4</priority>
   <chance>10</chance>
   <location>Bar</location>
   <faction>Za'lek</faction>
  </avail>
  <notes>
   <tier>2</tier>
  </notes>
 </mission>
 --]]
--[[
   Mission: The one with the Shopping

   Description: A Za'lek scientist asks the player to fetch some raw material that he needs to build his prototype.
   Multiple systems have to be visited and materials acquired from contact persons in the bar.

   Difficulty: Easy to Medium? Depending on whether the player lingers around too much and gets caught.

   Author: fart but based on Mission Ideas in wiki: wiki.naev.org/wiki/Mission_Ideas
--]]

local fmt = require "format"
require "proximity"
local sciwrong = require "common.sciencegonewrong"


-- set mission variables
t_sys = { __save=true }
t_pla = { __save=true }
t_pla[1], t_sys[1] = planet.getS("Vilati Vilata")
t_pla[2], t_sys[2] = planet.getS("Waterhole's Moon")
-- t_x[3] is empty bc it depends on where the mission will start finally. (To be set in mission.xml and then adjusted in the following campaign missions)
--t_pla[3], t_sys[3] = planet.getS("Gastan")
pho_mny = 50e3
reward = 1e6

function create ()
   -- Variable set up and clean up
   var.push( sciwrong.center_operations, planet.cur():nameRaw() )
   t_pla[3], t_sys[3] = sciwrong.getCenterOperations()

   -- Spaceport bar stuff
   misn.setNPC( _("A scientist"), "zalek/unique/geller.webp", _("You see a scientist talking to various pilots. Perhaps you should see what he's looking for.") )
end
function accept()
   -- Mission details:
   if not tk.yesno( _([[In the bar]]), _([["Oh, hello! You look like you're a pilot; is that right? I've got a job for you. Allow me to introduce myself; my name is Dr. Geller, and I am on the brink of revolutionizing science! I've basically already done it; there's just some minor fiddling to do. Would you like to help me out? I just need you to find some samples that I can study."]]) ) then
      tk.msg(_("No Science Today"), _("I guess you don't care for science..."))
      misn.finish()
   end
   tk.msg( _([[In the bar]]), _([["Excellent! Here is the list." He hands you a memory chip and turns away even before you can say anything and without giving you any cash to actually do his shopping. Once you check the list you find that it contains not only a list of materials he needs, but also information where to retrieve these and a list of contact traders.]]) )
   misn.accept()
   misn.osdCreate(_("The one with the Shopping"), {
      fmt.f(_("Go to the {sys} system and talk to the trader on {pnt}"), {sys=t_sys[1], pnt=t_pla[1]}),
   })
   misn.setDesc(_("You've been hired by Dr. Geller to collect some materials he urgently needs for his research."))
   misn.setTitle(_("The one with the Shopping"))
   misn.setReward(_("The gratitude of science and a bit of compensation"))
   misn_mark = misn.markerAdd( t_sys[1], "high" )
   talked = false
   lhook1 =  hook.land("land1", "land")
end

function land1()
   local trd1_desc = _("A scientist conspicuously sits in the corner. Perhaps he might be the person you're supposed to get this stuff for.")
   if planet.cur() == t_pla[1] and not talked and not traded then
      bar1pir1 = misn.npcAdd("first_trd", _("Trader"), "neutral/scientist3.webp", trd1_desc)
   elseif planet.cur() == t_pla[1] and talked and traded1 then
      bar1pir1 = misn.npcAdd("third_trd", _("Trader"), "neutral/scientist3.webp", trd1_desc)
   end
end

function land2()
   if planet.cur() == t_pla[2] and talked and not traded1 then
      bar2pir1 = misn.npcAdd("second_trd", _("Contact Person"), "neutral/unique/dealer.webp", _("You see a shifty-looking dealer of some kind. Maybe he has what you're looking for."))
   end
end

-- first trade: send player 2 2nd system, if he goes back here, tell them to get going...
function first_trd()
  if talked then
     tk.msg(_([[In the bar]]), _([["What are you still doing here? No phosphine, no trade."]]))
     return
  else
     tk.msg(_([[In the bar]]), _([["With what can I help you, my friend?" says the shifty figure. You hand him the memory chip the scientist handed you.]]))
     tk.msg(_([[In the bar]]), fmt.f(_([["Of course I have what you need. I'll trade it for some 3t phosphine. You can find it on {pnt} in the {sys} system."]]), {pnt=t_pla[2], sys=t_sys[2]}))
     talked = true
  end

  misn.osdCreate(_("The one with the Shopping"), {
     fmt.f(_("Go to the {sys} system and talk to the contact person on {pnt}"), {sys=t_sys[2], pnt=t_pla[2]}),
  })

  misn.markerMove(misn_mark, t_sys[2])

  lhook2 = hook.land("land2", "land")

end
-- 2nd trade: Get player the stuff and make them pay, let them be hunted by the police squad
function second_trd()
  misn.npcRm(bar2pir1)
  if not tk.yesno( _([[In the bar]]), fmt.f(_([["You approach the dealer and explain what you are looking for. He raises his eyebrow. "It will be {credits}. But if you get caught by the authorities, you're on your own. Far as I'm concerned I never saw you. Deal?"]]), {credits=fmt.credits(pho_mny)}) ) then
     tk.msg(_([[In the bar]]), _([["Then we have nothing to to discuss."]]))
     return
  end
  -- take money from player, if player does not have the money, refuse
  if player.credits() < 50e3 then
     tk.msg(_([[In the bar]]), _([["You don't have enough money. Stop wasting my time."]]))
     return
  end
  player.pay(-pho_mny)
  local c = misn.cargoNew(N_("Phosphine"), N_("A colourless, flammable, poisonous gas."))
  carg_id = misn.cargoAdd(c, 3)
  tk.msg(_([[In the bar]]), _([["Pleasure to do business with you."]]))
  misn.osdCreate(_("The one with the Shopping"), {
     fmt.f(_("Return to the {sys} system to the trader on {pnt}"), {sys=t_sys[1], pnt=t_pla[1]}),
  })
 -- create hook that player will be hailed by authorities bc of toxic materials
  misn.markerMove(misn_mark, t_sys[1])
  hook.rm(lhook2)
  hook.enter("sys_enter")
  traded1 = true
end

-- 3rd trade: Get the stuff the scientist wants
function third_trd()
  tk.msg(_([[In the bar]]), _([["Ah, yes indeed," he says as he inspects a sample in front of him. "That will do. And here, as promised: a piece of a ghost ship from the nebula. 100% authentic! At least, according to my supplier."]]))

  misn.npcRm(bar1pir1)
  misn.cargoRm(carg_id)
  player.msg(t_sys[3]:name())
  misn.osdCreate(_("The one with the Shopping"), {
     fmt.f(_("Return to the {sys} system and deliver to Dr. Geller on {pnt}"), {sys=t_sys[3], pnt=t_pla[3]}),
  })

  misn.markerMove(misn_mark, t_sys[3])

  hook.rm(lhook1)

  traded2 = true
  lhook1 = hook.land("fnl_ld", "land")
end

-- final land: let the player land and collect the reward
function fnl_ld ()
   if planet.cur() == t_pla[3] and traded2 then
      tk.msg(_([[In the bar]]),_([[Dr. Geller looks up at you as you approach. "Do you have what I was looking for?" You present the ghost ship piece and his face begins to glow. "Yes, that's it! Now I can continue my research. I've been looking everywhere for a sample!" You ask him about the so-called ghost ships. He seems amused by the question. "Some people believe in ridiculous nonsense related to this. There is no scientific explanation for the origin of these so-called ghost ships yet, but I think it has to do with some technology involved in the Incident. Hard to say exactly what, but hey, that's why we do research!"]]))
      tk.msg(_([[In the bar]]),_([[As he turns away, you audibly clear your throat, prompting him to turn back to you. "Oh, yes, of course you want some payment for your service. My apologies for forgetting." He hands you a credit chip with your payment. "I might need your services again in the future, so do stay in touch!"]]))
      player.pay(reward)
      sciwrong.addLog( fmt.f( _([[You helped Dr. Geller at {pnt} in the {sys} system toobtain a "ghost ship piece" for his research. When you asked about these so-called ghost ships, he seemed amused. "Some people believe in ridiculous nonsense related to this. There is no scientific explanation for the origin of these so-called ghost ships yet, but I think it has to do with some technology involved in the Incident. Hard to say exactly what, but hey, that's why we do research!"]]), {pnt=t_pla[3], sys=t_sys[3] } ) )
      misn.finish(true)
   end
end
-- when the player takes off the authorities will want them
function sys_enter ()
   if system.cur() == t_sys[2] then
      hook.timer(7.0, "call_the_police")
   end
end
function call_the_police ()
   spwn_police()
   tk.msg(_([[On the intercom]]),_([["We have reason to believe you are carrying controlled substances without a proper license. Please stop your ship and prepare to be boarded."]]))
   tk.msg(_([[On the intercom]]),_([["Stand down for inspection."]]))
   if boardh == nil then
      boardh = hook.pilot(player.pilot(), "disable", "go_board")
   end
end

function spwn_police ()
      lance1 = pilot.add( "Empire Lancelot", "Empire", system.get("Provectus Nova") )
      lance2 = pilot.add( "Empire Lancelot", "Empire", system.get("Provectus Nova") )
      adm1 = pilot.add( "Empire Admonisher", "Empire", system.get("Provectus Nova") )
      -- Re-outfit the ships to use disable weapons. Make a proper function for that.
      lance1:outfitRm("all")
      lance1:outfitAdd("Heavy Ion Cannon", 1)
      lance1:outfitAdd("Ion Cannon", 1)
      lance1:outfitAdd("TeraCom Medusa Launcher", 2)
      lance2:outfitRm("all")
      lance2:outfitAdd("Heavy Ion Cannon", 1)
      lance2:outfitAdd("Ion Cannon", 1)
      lance2:outfitAdd("TeraCom Medusa Launcher", 2)

      adm1:outfitRm("all")
      adm1:outfitAdd("Heavy Ion Turret", 2)
      adm1:outfitAdd("EMP Grenade Launcher", 1)
      adm1:outfitAdd("Ion Cannon", 2)
      lance1:setHostile(true)
      lance2:setHostile(true)
      adm1:setHostile(true)
end
-- move to the player ship

function go_board ()
   if adm1:exists() then
      adm1:control()
      adm1:setHostile(false)
      adm1:moveto(player.pos())
      admho = hook.pilot(adm1, "idle", "fine_vanish")
   end
   if lance1:exists() then
      lance1:control()
      lance1:setHostile(false)
      lance1:moveto(player.pos())
      l1ho = hook.pilot(lance1, "idle", "fine_vanish")
   end
   if lance2:exists() then
      lance2:control()
      lance2:setHostile(false)
      lance2:moveto(player.pos())
      l2ho = hook.pilot(lance2, "idle", "fine_vanish")
   end
end
-- display msgs and have the ships disappear and fail the mission...
function fine_vanish ()
   fine = 100e3
   tk.msg(_([[On your ship]]),_([["You are accused of violating regulation on the transport of toxic materials. Your ship will be searched now. If there are no contraband substances, we will be out of your hair in just a moment."]]))
   tk.msg(_([[On your ship]]), fmt.f(_([[The inspectors search through your ship and cargo hold. It doesn't take long for them to find the phosphine; they confiscate it and fine you {credits}.]]), {credits=fmt.credits(fine)}))
   if player.credits() > fine then
      player.pay(-fine)
   else
      player.pay(-player.credits())
   end
   misn.cargoRm(carg_id)
   if adm1:exists() then
      adm1:hyperspace()
   end
   if lance1:exists() then
      lance1:hyperspace()
   end
   if lance2:exists() then
      lance2:hyperspace()
   end
   player.msgClear()
   player.msg(_("Mission failed!"))
   hook.rm(l1ho)
   hook.rm(l2ho)
   hook.rm(admho)
   misn.finish(false)
end
