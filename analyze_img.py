import sys
from PIL import Image

def analyze_image(path):
    try:
        img = Image.open(path).convert("RGBA")
        print(f"Size: {img.size}")
        
        colors = img.getcolors(maxcolors=100000)
        if colors:
            colors.sort(key=lambda x: x[0], reverse=True)
            print("Top 5 colors (count, (R, G, B, A)):")
            for i in range(min(5, len(colors))):
                print(colors[i])
        else:
            print("Too many colors to count easily.")
            
        # check top-left pixel
        print(f"Top-left pixel: {img.getpixel((0, 0))}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    analyze_image(sys.argv[1])
