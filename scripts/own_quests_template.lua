--Here is a template to make your own quests!
--Follow the hints.

--Copy this file in the scripts folder of this mod and rename it to own_quests.lua to use it.
--This will only be used if you are the server!

return {

--If you want to add multiple quests, copy from here till....

	{
	name = "Questname",		--name of your quest
	victim = "Victim", 		--the prefab name of the enemy that should be killed to accomplish the quest, see https://dontstarve.fandom.com/wiki/ and look at the enemy to find the prefab name under Code on the right side under the picture.
	counter_name = nil, -- if you want to have a custom word in place of the victims name, make victim = "" and enter the name you want here. It will appear instead of the victims name in the quest log.
	hovertext = nil, --Add a string here if you want a certain phrase to appear when hovering over the victims symbol.
	description = "This is a description", --Write the description of the quest that can be seen when clicking on description
	amount = 5,				--the amount of reached goals necessary to complete the quest
	rewards = {
		pigskin = 3, 
		butterflywings = 3,
		}, --the rewards, pigskin is the prefab name of the pig skin and 3 is the amount of pig skins that will be gained when completing the mission. If you want more rewards, you can add them by adding a new line with prefab = amount_of_item,
	points = 100, -- the amount of points that will be rewarded when completing the mission
	start_fn = nil, -- for the more experienced who want to do something else that just kill enemies. This function is run when the quest is accepted and when the game starts if the quest is accepted with the argument of the player, the amount of reached goals and the quest name.
	onfinished = nil, --also for the more experienced, here you can add a function that runs when the quest is completed to do more things that are not included in the mod. Gets the arguments of the player and item, a table of the rewards received.
	difficulty = 1,	--choose a difficulty that will be shown, can be chosen between 1 and 5 with 1 easiest and 5 the most difficult one
	character = nil, --used if the quest should only be able to be gotten by a specific character.
	},


--......here everything and paste it under this line.


}