import asyncio
import aiohttp
import time
import csv

"""
The following code was used to scrape gyms in Budapest.
Since the number of free API calls for Places API is limited by Google, we could only scrape Budapest for possible gyms and outdoors workout places.
We also plan to scrape gyms in other major cities as well.
"""

API_KEY = "..."
SEARCH_RADIUS = 500  # 500 meters search radius
GYM_TYPE = "gym"

# Define Budapest bounding box
LAT_NORTH, LAT_SOUTH = 47.6066, 47.4120
LON_WEST, LON_EAST = 18.9200, 19.3260

# Define grid step size (~500m in lat/lon degrees)
LAT_STEP = 0.0045
LON_STEP = 0.0070

def frange(start, stop, step):
    while start <= stop:
        yield start
        start += step

latitudes = [round(lat, 6) for lat in frange(LAT_SOUTH, LAT_NORTH, LAT_STEP)]
longitudes = [round(lon, 6) for lon in frange(LON_WEST, LON_EAST, LON_STEP)]
grid_points = [(lat, lon) for lat in latitudes for lon in longitudes]

async def fetch_gyms(session, lat, lon):
    gyms = []
    url = f"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location={lat},{lon}&radius={SEARCH_RADIUS}&type={GYM_TYPE}&key={API_KEY}"

    while url:
        async with session.get(url) as response:
            data = await response.json()

            if "results" in data:
                for gym in data["results"]:
                    name = gym.get("name", "Unknown Gym")
                    address = gym.get("vicinity", "No Address")
                    place_id = gym.get("place_id", "No ID")
                    lat = gym["geometry"]["location"]["lat"]
                    lon = gym["geometry"]["location"]["lng"]
                    gyms.append((name, address, place_id, lat, lon))

            # Handle pagination
            next_page_token = data.get("next_page_token")
            if next_page_token:
                await asyncio.sleep(2)  # Required delay for token activation
                url = f"https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken={next_page_token}&key={API_KEY}"
            else:
                url = None 

    return gyms

async def fetch_all_gyms():
    """Fetch gyms for all grid points concurrently using async."""
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_gyms(session, lat, lon) for lat, lon in grid_points]
        result = await asyncio.gather(*tasks)
        all_gyms = set()
        for gyms in result:
            all_gyms.update(gyms)
        return all_gyms

def save_gyms_to_csv(gyms):
    with open("budapest_gyms.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Name", "Address", "Place_ID", "Latitude", "Longitude"])
        for gym in gyms:
            writer.writerow(gym)

start_time = time.time()
gyms = asyncio.run(fetch_all_gyms())
save_gyms_to_csv(gyms)
end_time = time.time()

print(f"Scraping completed in {end_time - start_time:.2f} seconds!")
print(f"{len(gyms)} gyms saved to.")
