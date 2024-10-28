$(document).ready(function () {
    const $parentDiv = $(".parent-div").hide();
    const $scaryImage = $(".scary-image").hide();
    const $bloodOverlay = $("#blood-overlay");

    function playSound(id, volume) {
        const audio = $(`#${id}`)[0];
        audio.volume = volume;

        audio.play().catch(error => {
            console.error("Error playing the audio:", error);
        });
    }

    function stopSound(id) {
        const audio = $(`#${id}`)[0];
        audio.pause();
        audio.currentTime = 0;
    }

    function showBloodEffect() {
        $bloodOverlay.css("opacity", 0.2);
        playSound("damage-sound", 0.5);

        setTimeout(() => {
            $bloodOverlay.css("opacity", 0);
        }, 1000);
    }

    function updateCollectedCount(id, count) {
        $(`${id}`).text(count);
    }

    function handleScareEffect() {
        playSound("scary-sound", 1.0);
        $scaryImage.show();

        setTimeout(() => {
            stopSound("scary-sound");
            $scaryImage.hide();
        }, 3000);
    }

    window.addEventListener("message", (event) => {
        const { action, pumpkinsCollected, zombiesCollected } = event.data;

        switch (action) {
            case "startEvent":
                playSound("background-music", 0.02);
                $parentDiv.show();
                break;

            case "stopEvent":
                $parentDiv.hide();
                stopSound("background-music");
                break;

            case "updateCard":
                console.log(pumpkinsCollected !== undefined)
                console.log(zombiesCollected !== undefined)
                if (pumpkinsCollected !== undefined) {
                    updateCollectedCount("#pumpkins-collected-value", pumpkinsCollected);
                }
                if (zombiesCollected !== undefined) {
                    updateCollectedCount("#zombies-collected-value", zombiesCollected);
                }
                break;

            case "applyDamage":
                showBloodEffect();
                break;

            case "scareMf":
                handleScareEffect();
                break;

            default:
                console.warn("Unknown action:", action);
                break;
        }
    });
});
