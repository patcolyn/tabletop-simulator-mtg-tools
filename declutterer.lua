-- Declutterer

function onLoad()
	if not string.match(Info.name, "^MTG EDH [468]%-player %(π%)$") then return end
	
	local declutterObject = nil
	for _,obj in ipairs(getObjects()) do
		if obj.getName() == "Table Instructions" then
			declutterObject = obj
		end
	end

    if declutterObject then declutterObject.call("closeSelf") end

    -- Custom star field
    Backgrounds.setCustomURL("https://steamusercontent-a.akamaihd.net/ugc/14883842009767733466/FBF8E496D1B826BEC2D52A9E57AE275F6B486061/")
    
    MusicPlayer.setPlaylist({})
    -- Empty audio clip
    MusicPlayer.setCurrentAudioclip({url="https://steamusercontent-a.akamaihd.net/ugc/10070388021481426706/62D820A785B8DF98FAA1B297BC6A80B4D21EB414/",title=" "})

    --self.destruct()
end
