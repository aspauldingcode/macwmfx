from PIL import Image, ImageDraw, ImageFilter
import os

def generate_shadow():
    # Create a new RGBA image (transparent background)
    width = 3
    height = 3
    image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Define shadow properties
    shadow_color = (255, 0, 0, 32)  # Light red shadow
    border_color = (139, 0, 0, 255)  # Dark red border
    
    # Draw the base shadow
    draw.point([(1, 1)], fill=shadow_color)
    
    # Draw the border
    for x in range(3):
        for y in range(3):
            if x == 0 or x == 2 or y == 0 or y == 2:
                draw.point([(x, y)], fill=border_color)
    
    # Create a new RGBA image (transparent background)
    width = 27
    height = 27
    shadow_image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    border_image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw_shadow = ImageDraw.Draw(shadow_image)
    draw_border = ImageDraw.Draw(border_image)
    
    # Define shadow properties
    shadow_color = (255, 0, 0, 128)  # More visible red shadow
    border_color = (139, 0, 0, 255)  # Dark red, fully opaque
    
    # Draw the shadow on separate image
    draw_shadow.rectangle(
        [(3, 3), (width-3, height-3)],
        fill=shadow_color
    )
    
    # Blur only the shadow
    shadow_image = shadow_image.filter(ImageFilter.GaussianBlur(radius=1.5))
    
    # Draw the border on separate image
    draw_border.rectangle(
        [(3, 3), (width-3, height-3)],
        outline=border_color,
        width=1
    )
    
    # Combine the images
    image = Image.alpha_composite(shadow_image, border_image)
    
    # Save the image, overwriting if exists
    shadow_path = "/Library/wsfun/shadow.png"
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(shadow_path), exist_ok=True)
    
    image.save(shadow_path, "PNG")

if __name__ == "__main__":
    generate_shadow()
