# =================================================================
# Loading Overlay
# =================================================================

#' Add a loading overlay to a dashboard page
#'
#' Creates an animated loading overlay that appears when the page loads
#' and automatically fades out after a specified duration. Useful for
#' providing visual feedback while charts and visualizations are rendering.
#'
#' @param text Text to display in the loading overlay (default: "Loading")
#' @param timeout_ms Duration in milliseconds before the overlay hides (default: 2200)
#' @param theme Visual theme for the overlay. One of:
#'   \itemize{
#'     \item \code{"light"} - Clean white overlay with subtle shadow
#'     \item \code{"glass"} - Glassmorphic semi-transparent overlay
#'     \item \code{"dark"} - Dark gradient overlay
#'     \item \code{"accent"} - Light overlay with blue accents
#'   }
#'
#' @return An htmltools tag object containing the overlay HTML, CSS, and JavaScript
#'
#' @examples
#' \dontrun{
#' # In a Quarto document R chunk:
#' dashboardr::add_loading_overlay("Loading Dashboard...", 2000, "glass")
#' }
#'
#' @export
add_loading_overlay <- function(
  text = "Loading",
  timeout_ms = 2200,
  theme = c("light", "glass", "dark", "accent")
) {
  theme <- match.arg(theme)
  
  css <- switch(
    theme,
    light = "
      #page-loading-overlay {
        position: fixed; inset: 0; z-index: 9999;
        display: flex; align-items: center; justify-content: center;
        background: rgba(255,255,255,0.98);
        backdrop-filter: blur(10px);
        transition: opacity .35s ease, visibility .35s ease;
      }
      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }
      .plo-card {
        background: rgba(255,255,255,0.85);
        border: 1px solid rgba(0,0,0,0.03);
        border-radius: 18px;
        padding: 1rem 1.2rem .9rem 1.2rem;
        display: flex; flex-direction: column; gap: .5rem; align-items: center;
        box-shadow: 0 14px 38px rgba(15,23,42,0.05);
        min-width: 185px;
      }
      .plo-spinner {
        width: 38px; height: 38px; border-radius: 9999px;
        border: 3px solid rgba(148,163,184,0.32);
        border-top-color: rgba(15,23,42,0.9);
        animation: plo-spin 1s linear infinite;
      }
      @keyframes plo-spin { to { transform: rotate(360deg); } }
      .plo-title { font-size: .8rem; font-weight: 500; color: rgba(15,23,42,0.85); }
      .plo-sub { font-size: .68rem; color: rgba(15,23,42,0.4); }
    ",
    glass = "
      #page-loading-overlay {
        position: fixed; inset: 0; z-index: 9999;
        display: flex; align-items: center; justify-content: center;
        background: rgba(255,255,255,0.45);
        backdrop-filter: blur(16px);
        transition: opacity .35s ease, visibility .35s ease;
      }
      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }
      .plo-card {
        background: rgba(255,255,255,0.25);
        border: 1px solid rgba(255,255,255,0.55);
        border-radius: 20px;
        padding: 1.1rem 1.3rem 1rem 1.3rem;
        display: flex; flex-direction: column; gap: .5rem; align-items: center;
        box-shadow: 0 18px 45px rgba(15,23,42,0.08);
        min-width: 190px;
      }
      .plo-spinner {
        width: 40px; height: 40px;
        border-radius: 9999px;
        border: 3px solid rgba(255,255,255,0.4);
        border-top-color: rgba(15,23,42,0.75);
        animation: plo-spin 1s linear infinite;
      }
      @keyframes plo-spin { to { transform: rotate(360deg); } }
      .plo-title { font-size: .78rem; font-weight: 500; color: rgba(15,23,42,0.88); }
      .plo-sub { font-size: .65rem; color: rgba(15,23,42,0.5); }
    ",
    dark = "
      #page-loading-overlay {
        position: fixed; inset: 0; z-index: 9999;
        display: flex; align-items: center; justify-content: center;
        background: radial-gradient(circle at top, #0f172a 0%, #020617 45%, #000 100%);
        backdrop-filter: blur(10px);
        transition: opacity .35s ease, visibility .35s ease;
      }
      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }
      .plo-card {
        background: rgba(15,23,42,0.2);
        border: 1px solid rgba(255,255,255,0.06);
        border-radius: 18px;
        padding: 1rem 1.1rem .85rem 1.1rem;
        display: flex; flex-direction: column; gap: .45rem; align-items: center;
        box-shadow: 0 18px 45px rgba(0,0,0,0.3);
        min-width: 180px;
      }
      .plo-spinner {
        width: 36px; height: 36px;
        border-radius: 9999px;
        border: 3px solid rgba(15,23,42,0.45);
        border-top-color: rgba(255,255,255,0.85);
        animation: plo-spin 1s linear infinite;
      }
      @keyframes plo-spin { to { transform: rotate(360deg); } }
      .plo-title { font-size: .78rem; font-weight: 500; color: #fff; }
      .plo-sub { font-size: .64rem; color: rgba(255,255,255,0.4); }
    ",
    accent = "
      #page-loading-overlay {
        position: fixed; inset: 0; z-index: 9999;
        display: flex; align-items: center; justify-content: center;
        background: radial-gradient(circle, rgba(255,255,255,0.98) 0%, rgba(245,248,255,0.95) 60%);
        backdrop-filter: blur(10px);
        transition: opacity .35s ease, visibility .35s ease;
      }
      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }
      .plo-card {
        background: #fff;
        border: 1px solid rgba(59,130,246,0.12);
        border-radius: 16px;
        padding: .95rem 1.25rem .75rem 1.25rem;
        display: flex; flex-direction: column; gap: .45rem; align-items: center;
        box-shadow: 0 14px 30px rgba(59,130,246,0.12);
        min-width: 180px;
      }
      .plo-spinner {
        width: 34px; height: 34px;
        border-radius: 9999px;
        border: 3px solid rgba(59,130,246,0.15);
        border-top-color: rgba(59,130,246,0.9);
        animation: plo-spin .85s linear infinite;
      }
      @keyframes plo-spin { to { transform: rotate(360deg); } }
      .plo-title { font-size: .78rem; font-weight: 500; color: rgba(15,23,42,0.88); }
      .plo-sub { font-size: .64rem; color: rgba(15,23,42,0.35); }
    "
  )
  
  htmltools::tags$div(
    htmltools::tags$style(htmltools::HTML(css)),
    htmltools::tags$div(
      id = "page-loading-overlay",
      htmltools::tags$div(
        class = "plo-card",
        htmltools::tags$div(class = "plo-spinner"),
        htmltools::tags$div(class = "plo-title", text)
      )
    ),
    htmltools::tags$script(htmltools::HTML(sprintf("
      window.addEventListener('load', function() {
        setTimeout(function() {
          var el = document.getElementById('page-loading-overlay');
          if (el) el.classList.add('hide');
        }, %d);
      });
    ", timeout_ms)))
  )
}

