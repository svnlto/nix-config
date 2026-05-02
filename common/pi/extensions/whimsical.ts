import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const messages = [
  "Schlepping...", "Combobulating...", "Vibing...", "Spelunking...", "Transmuting...",
  "Pontificating...", "Cogitating...", "Noodling...", "Percolating...", "Ruminating...",
  "Fermenting...", "Brewing...", "Contemplating...", "Mulling...", "Woolgathering...",
  "Dithering...", "Faffing...", "Tinkering...", "Finagling...", "Wrangling...",
  "Galumphing...", "Meandering...", "Traipsing...", "Bumbling...", "Futzing...",
  "Kerfuffling...", "Bamboozling...", "Discombobulating...", "Confabulating...", "Flummoxing...",
  "Snorkeling...", "Yodeling...", "Zigzagging...", "Pirouetting...", "Canoodling...",
  "Skedaddling...", "Skittering...", "Sashaying...", "Swashbuckling...", "Oscillating...",
  "Effervescing...", "Beguiling...", "Mesmerizing...", "Bedazzling...", "Scintillating...",
  "Sublimating...", "Amalgamating...", "Procrastinating...", "Lollygagging...", "Sleuthing...",
  "Fossicking...", "Foraging...", "Absquatulating...", "Freestyling...", "Frolicking...",
  "Blorping...", "Flonking...", "Snurfling...", "Whomping...", "Zorping...",
  "Squonking...", "Squelching...", "Burbling...", "Splooshing...", "Kerplunking...",
  "Snazzifying...", "Pizzazzing...", "Doodling...", "Squiggling...", "Gibbering...",
  "Blathering...", "Smoldering...", "Teetering...", "Jittering...", "Shattering...",
  "Yammering...", "Stammering...", "Shimmering...", "Glimmering...", "Thrumming...",
  "Fumbling...", "Grumbling...", "Stumbling...", "Tumbling...", "Crumbling...",
  "Wangling...", "Dangling...", "Jangling...", "Mingling...", "Tingling...",
  "Tokenmaxxing...",
  "Consulting the void...", "Asking the electrons...", "Bribing the compiler...",
  "Negotiating with entropy...", "Whispering to the bits...", "Massaging the heap...",
  "Appeasing the garbage collector...", "Herding pointers...", "Untangling spaghetti...",
  "Waxing philosophical...", "Reading tea leaves...", "Sacrificing to the demo gods...",
  "Caffeinating...", "Existentially questioning...", "Stroking chin thoughtfully...",
  "Staring into the abyss...", "Abyss staring back...", "Ascending to a higher plane...",
  "Communing with the machine spirit...", "Performing arcane rituals...",
  "Divining the answer...", "Scrying the codebase...", "Dowsing for bugs...",
  "Aligning the chakras...", "Reticulating splines...", "Reversing the polarity...",
  "Calibrating the flux capacitor...", "Hoping for the best...", "Manifesting solutions...",
  "Politely asking the CPU...", "Flirting with the database...", "Sweet-talking the API...",
  "Having words with the cache...", "Pleading with the logs...", "Making offerings to the CI...",
  "Consulting the rubber duck...", "Interrogating the stack trace...",
  "Schmoozing the network...", "Wining and dining the servers...",
  "Taking the bytes out for lunch...", "Giving the code a pep talk...",
  "Kicking the tires...", "Greasing the gears...", "Stoking the furnace...",
  "Watering the logic tree...", "Pruning the decision branches...", "Taming wild pointers...",
  "Teaching old code new tricks...", "Dancing with dependencies...", "Tangoing with type errors...",
  "Having a moment of clarity...", "Receiving transmissions from the cloud...",
  "Asking the hamsters to run faster...", "Flattering the floating points...",
  "Enchanting the error handlers...", "Hexing the hexadecimals...", "Blessing the build process...",
  "Exorcising the exceptions...", "Liberating the lambdas...", "Unraveling the regex...",
  "Excavating ancient APIs...", "Spelunking through the stack...", "Scuba diving in the data...",
  "Bungee jumping into the backend...", "Surfing the syntax waves...",
  "Mountain climbing the modules...", "Cherry-picking the commits...",
  "Barbecuing the bugs...", "Roasting the race conditions...", "Caramelizing the callbacks...",
  "Smoking the subroutines...", "Curing the code smells...", "Aerating the arrays...",
  "Aging the algorithms gracefully...", "Seasoning the solutions...", "Plating the output nicely...",
  "Sprinkling some magic dust...", "Folding in the features...", "Rolling out the runtime...",
  "Baking at 350 kilobytes...", "Frosting the functions...", "Topping with tests...",
  "Slop forking open source...",
];

function pickRandom(): string {
  return messages[Math.floor(Math.random() * messages.length)]!;
}

export default function (pi: ExtensionAPI) {
  pi.on("turn_start", async (_event, ctx) => {
    ctx.ui.setWorkingMessage(pickRandom());
  });

  pi.on("turn_end", async (_event, ctx) => {
    ctx.ui.setWorkingMessage();
  });
}
