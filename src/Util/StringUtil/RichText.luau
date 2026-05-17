local RichText = {}

function RichText.bold(text : string) : string
	return string.format("<b>%s</b>", text)
end

function RichText.strikethrough(text : string) : string
	return string.format("<s>%s</s>", text)
end

function RichText.underline(text : string) : string
	return string.format("<u>%s</u>", text)
end

function RichText.italic(text : string) : string
	return string.format("<i>%s</i>", text)
end

function RichText.size(text : string, size : number) : string
	return string.format('<font size="%d">%s</font>', size, text)
end

function RichText.stroke(text : string, stroke_color : Color3, thickness : number, transparency : number) : string
	return string.format('<stroke color="rgb(%d,%d,%d)" joins="miter" thickness="%d" transparency="%f">%s</stroke>', stroke_color.R*255, stroke_color.G*255, stroke_color.B*255, thickness, transparency, text)
end

function RichText.color(text : string, rgb : Color3) : string
	return string.format('<font color="rgb(%d,%d,%d)">%s</font>',rgb.R*255,rgb.G*255,rgb.B*255,text)
end

function RichText.transparency(text : string, transparency : number) : string
	return string.format('<font transparency="%f">%s</font>', transparency, text);
end

return RichText
