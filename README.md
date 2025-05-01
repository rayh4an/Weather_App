
Author: Hasin Rahman and Rayhaan Mohamed.

Weatherly – Flutter Weather App
Weatherly is a feature-rich Flutter mobile application that provides real-time and forecast weather information. Users can manage multiple cities, receive weather alerts, switch temperature units, and share personalized weather postcards with optional images.

Features include: 

Location-Based Weather
Fetches weather data for the user's current location using geolocation.

City Management
Allows users to add, view, and delete multiple city locations. Cities are added using a search interface with suggestions including city and country names.

Weather Forecasts
Displays current temperature, 24-hour forecast, and 7-day forecast using OpenWeatherMap data.

Sunrise and Sunset Times
Accurately shows sunrise and sunset times based on the local time zone of each city.

Temperature Units
Supports switching between Celsius and Fahrenheit. All alerts and settings are respected across units.

Radar Map Integration
Includes an interactive map with zoom functionality and temperature overlay from OpenWeatherMap.

Weather Alerts
Users can set alerts for high and low temperatures, as well as rain or snow conditions.

User Feedback and Sharing
Users can submit weather feedback and view a global feed of shared experiences. They can also generate and share weather postcards with optional custom images.

Authentication and User Management
Supports user registration and login using Firebase Authentication. Each user's data (cities, preferences, feedback) is tied to their unique account.

Real-Time Cloud Sync
Utilizes Firebase Cloud Firestore to store and sync user data across devices.

Run the application: 
Login page: 
To run the app for a first time user they would need to register using their email at the login page and then they will create a password for their login so they can easily login next time. 

Homepage: 
When the user logs in they will be greeted with a welcome message then on the bottom right corner they will see two buttons one is to add and the other one is to get weather info for the current location of the user. 
When they click the current location button they will see their current city is poped up on the list of the homepage and they can also the add more city then whenever they click on a city they will be directed to a detail weather page app. 

Detail weather page:
In the detail weather page they can see the current temperature at the moment and the sunrise and the sunset time (in local time format relative to the location). They can also see the hourly weather along with seven day forcast. The color of the app changes as well, depending on the time of the day. Then when we scroll down we can see a map which has temp button that will show the heat map of over a satellite view and then plus and minus button to zoom in and out. 
Then at the bottom there is an option to give feedback of the current weather that the user is experience right now and those messages are shared with the other users on the app. Those messages can be seen after the feedback section and once that is complete they can share a post card of the current weather. The postcard will have default picture of the current weather however, they are allowed to put in their own image on that post card as well an then they can use the share button to share that post card. 

Setting page:
In this page they can set alerts for rain and snow and also change the temperature unit from F to C. They can also set custom temperature unit for high temperature aler and for low temperature alerts as well. So when they go to a detail page of a city if the temp of that city crosses the low or the high temp they will be alerted or notified using a pop up. Same with rain and snow. Another thing is that they can choose background/wallpaper from this page from the collection which was already provided. 

Then lastly the user can logout from the settings page and all of their data will be saved to their profile. 
