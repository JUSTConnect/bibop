# Bipob Heavy Claw movable object rules

Heavy movable objects such as barrels and steel boxes are blocking world objects by default. Bipob cannot walk or route through their cells during normal movement.

Heavy Claw attachment is explicit: the claw stores the attached object id, the object cell at attachment time, and the anchor direction from Bipob to the object. The object must remain directly in front of Bipob along that anchor.

While attached, click-to-route movement is disabled so mouse pathing cannot turn Bipob, step onto the object cell, or perform an implicit object swap. Turning is also blocked until the claw is detached.

The current MVP movement rule is controlled dragging: Bipob backs away from the attached object, and the object moves into Bipob's previous cell so it remains held in front of Bipob. Moving forward into the attached object's cell is blocked; detach before normal movement or future push behavior.
