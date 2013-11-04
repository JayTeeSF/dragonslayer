var slaying = true; // global boolean
var totalDamage = 0; // global counter

// random => 0..1
// Floor rounds down
function youHitDragon() {
  return Math.floor(Math.random() * 2);
}

// anything less than 0.5 shrinks
// anything bigger than 0.5 gets multiplied to be > 1
// everything gets rounded down to either 0 or 1
// and in JS, 0 == false; 1 == true
function damageThisRound() {
  return Math.floor(Math.random() * 5 + 1); // => 1 - 5
}


while (slaying) {
    if (youHitDragon()) {
        console.log("You hit the dragon");
        totalDamage +=  damageThisRound();
        if (totalDamage >= 4) {
            console.log("...and he's dead!");
            slaying = false;
        } else {
            console.log("...and he's mad now, sucka!")
        }
    } else {
        console.log("Well, someone got hit ...but it wasn't the dragon!");
        slaying = false;
    }
}
