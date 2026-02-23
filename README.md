This is a brief description of Vendorpedia.

It is a World of Warcraft add-on designed to help users find items sold by vendors, such as reagents for professions or ingredients for cooking.
The user enters search terms either by typing manually or shift-clicking an item from a bag or other frame.
The results pane displays matches along with distance to the closest vendor and the expected price.
Clicking a search result item brings up a details pane with vendor name, zone, etc. If the user has TomTom installed and enabled, a button can be clicked to get a waypoint.

A quick explanation of each file:

ui.lua = all the main code, creates the UI, and all the necessary functions

data.lua = holds some test data from scanning NPCs; this will eventually hold all the real data

factions.lua = faction IDs for easier lookups when calculating prices


(It is worth noting that we gather faction standings to calculate the base (neutral) price, and then use that value to calculate what the user will pay.)
