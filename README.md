# Lecture 9 
Material Vertex Fragment shader:
For thix texture I applied it to a quad and I am able to change the X and Y Scale. 
What this means is that I can scale the texture on an object and modify it according 
to what I want.

Shadows With Texture Shader:
I was able to add this shader to a primitive object and mimic shadows 
while still being able to have a texture applied onto it. I can also change the tint on 
the object to apply shadows onto it.

Glass Shader / Texture:
For the glass shader I applied it to my plane but it wasn't working properly at the start.
I had help from the friends around me but at the end of the day I was able to change the 
Render queues and make it transperent. This took a long time to accomplish and was the hardest 
thing to implement in my engine.

Water Shader:
The water shader I added was able to work right away with no problems. I changed the wave frequency and amplitude to give
it a better effect. I also changed the speed to make it more noticable. 

Water Scrolling Shader:
This shader I added has a foam and water texture. For this shader I decided not to
change any valyes because it was already at a good consistent speed. 


Final Reflection:
Overall, during this class I was able to learn about material vertex fragment shader, shadows with texture,
glass shader, water shader and a scrolling water shader. The shaders weren't too hard to implement into unity
except for the glass texture however i was able to overcome that. The glass shader was changed adding in a Transperency queue
and changing some code within the half4 frag part of the shader. 

