document.querySelectorAll(".video__frame").forEach(function (frame) {
  var play = frame.querySelector(".video__play");
  if (!play) return;
  play.addEventListener("click", function () {
    var iframe = document.createElement("iframe");
    iframe.src = "https://www.youtube-nocookie.com/embed/" + frame.dataset.videoId +
      "?autoplay=1&rel=0&modestbranding=1&playsinline=1";
    iframe.title = "Hop Tales promo video";
    iframe.allow = "autoplay; encrypted-media; picture-in-picture; fullscreen";
    iframe.allowFullscreen = true;
    iframe.referrerPolicy = "strict-origin-when-cross-origin";
    frame.classList.add("is-playing");
    frame.replaceChildren(iframe);
    iframe.focus();
  }, { once: true });
});
