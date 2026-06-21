local RichText = {}

--[=[
	Makes text bold using rich text formatting.

	@param text string -- Text to make bold
	@return string -- Bold formatted text

	
	```lua
	local bold = RichText.bold("Important")
	```
]=]
function RichText.bold(text : string) : string
	return string.format("<b>%s</b>", text)
end

--[=[
	Strikes through text using rich text formatting.

	@param text string -- Text to strike through
	@return string -- Struck-through formatted text
]=]
function RichText.strikethrough(text : string) : string
	return string.format("<s>%s</s>", text)
end

--[=[
	Underlines text using rich text formatting.

	@param text string -- Text to underline
	@return string -- Underlined formatted text
]=]
function RichText.underline(text : string) : string
	return string.format("<u>%s</u>", text)
end

--[=[
	Makes text italic using rich text formatting.

	@param text string -- Text to make italic
	@return string -- Italic formatted text
]=]
function RichText.italic(text : string) : string
	return string.format("<i>%s</i>", text)
end

--[=[
	Sets font size for text using rich text formatting.

	@param text string -- Text to resize
	@param size number -- Font size value
	@return string -- Sized formatted text
]=]
function RichText.size(text : string, size : number) : string
	return string.format('<font size="%d">%s</font>', size, text)
end

--[=[
	Adds a stroke effect to text using rich text formatting.

	@param text string -- Text to stroke
	@param stroke_color Color3 -- Color of the stroke
	@param thickness number -- Thickness of the stroke
	@param transparency number -- Transparency of the stroke
	@return string -- Stroked formatted text
]=]
function RichText.stroke(text : string, stroke_color : Color3, thickness : number, transparency : number) : string
	return string.format('<stroke color="rgb(%d,%d,%d)" joins="miter" thickness="%d" transparency="%f">%s</stroke>', stroke_color.R*255, stroke_color.G*255, stroke_color.B*255, thickness, transparency, text)
end

--[=[
	Colors text using rich text formatting.

	@param text string -- Text to color
	@param rgb Color3 -- Color for the text
	@return string -- Colored formatted text

	
	```lua
	local red = RichText.color("Error", Color3.fromRGB(255, 0, 0))
	```
]=]
function RichText.color(text : string, rgb : Color3) : string
	return string.format('<font color="rgb(%d,%d,%d)">%s</font>',rgb.R*255,rgb.G*255,rgb.B*255,text)
end

--[=[
	Sets text transparency using rich text formatting.

	@param text string -- Text to make transparent
	@param transparency number -- Transparency value (0-1)
	@return string -- Transparent formatted text
]=]
function RichText.transparency(text : string, transparency : number) : string
	return string.format('<font transparency="%f">%s</font>', transparency, text);
end

return RichText
