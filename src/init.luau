--!native
--!optimize 2

--[=[
    @class Image
]=]

local ImageConstructors = {}
local Image = {}
Image.__index = Image

-- Type exports

export type Color = {
	r: number,
	g: number,
	b: number,
	a: number,
}

export type Image = typeof(setmetatable(
	{} :: {
		width: number,
		height: number,
		pixels: { number },
	},
	Image
))

-- Constructors

function ImageConstructors.new(width: number, height: number): Image
	return setmetatable({
		width = width,
		height = height,
		pixels = table.create(width * height * 4, 0),
	}, Image)
end

function ImageConstructors.fromPixels(width: number, height: number, pixels: { number }): Image
	local length = #pixels
	if length ~= width * height * 4 then
		error(`invalid pixel array size: {length}, expected {width} (width), * {height} (height) * 4`, 2)
	end

	return setmetatable({
		width = width,
		height = height,
		pixels = pixels,
	}, Image)
end

function ImageConstructors.fromEditableImage(image: EditableImage)
	local size = image.Size
	local pixels = image:ReadPixels(Vector2.zero, size) :: { number }

	return ImageConstructors.fromPixels(size.X, size.Y, pixels)
end

-- Methods

function Image.get(self: Image, x: number, y: number): Color
	local index = (x * self.width + y) * 4
	local pixels = self.pixels

	return {
		r = pixels[index],
		g = pixels[index + 1],
		b = pixels[index + 2],
		a = pixels[index + 3],
	}
end

function Image.set(self: Image, x: number, y: number, r: number, g: number, b: number, a: number)
	local index = (x * self.width + y) * 4
	local pixels = self.pixels

	pixels[index] = r
	pixels[index + 1] = g
	pixels[index + 2] = b
	pixels[index + 3] = a
end

function Image.iterate(self: Image): () -> (number, number, Color)
	local x, y = 0, 0
	local width, height, pixels = self.width, self.height, self.pixels

	return function()
		if x >= width then
			x = 0
			y += 1
		end

		if y < height then
			local index = (x + width * y) * 4
			x += 1

			return x,
				y,
				{
					r = pixels[index],
					g = pixels[index + 1],
					b = pixels[index + 2],
					a = pixels[index + 3],
				}
		end

		return nil :: never
	end
end

function Image.copyFrom(self: Image, other: Image, x: number, y: number)
	local width, height = other.width, other.height

	if self.width < width + x or self.height < height + y then
		error(`image dimensions mismatched`)
	end

	local target = self.pixels
	local source = other.pixels

	-- Not using get/set here for speed

	for i = 1, width do
		for j = 1, height do
			local s = ((i - 1) + width * (j - 1)) * 4
			local t = ((i - 1 + x) * self.width + (j - 1 + y)) * 4

			target[t] = source[s]
			target[t + 1] = source[s + 1]
			target[t + 2] = source[s + 2]
			target[t + 3] = source[s + 3]
		end
	end
end

function Image.clone(self: Image)
	return ImageConstructors.fromPixels(self.width, self.height, table.clone(self.pixels))
end

function Image.__iter(self: Image)
	return self:iterate()
end

return ImageConstructors
