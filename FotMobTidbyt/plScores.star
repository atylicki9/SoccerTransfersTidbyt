load("render.star", "render")
load("http.star", "http")

FOTMOB_URL = "https://www.fotmob.com/api/matches?id=47&tab=matches&type=league%timeZone=Americe/New_York"

TESTHOME_LOGO_URL = "https://images.fotmob.com/image_resources/logo/teamlogo/8463.png" # Pull these from api 
TESTAWAY_LOGO_URL = "https://images.fotmob.com/image_resources/logo/teamlogo/8586.png"
def main():
    match = http.get(FOTMOB_URL) # TODO: Add caching
    
    if match.status_code != 200:
        fail("FotMob request failed with status %d", match.status_code)

    homeTeam = match.json()["leagues"][0]["matches"][0]["home"]
    score = match.json()["leagues"][0]["matches"][0]["status"]["scoreStr"]
    awayTeam = match.json()["leagues"][0]["matches"][0]["away"]

    homeTeamName = homeTeam["name"]
    awayTeamName = awayTeam["name"]
    homeTeamId= homeTeam["id"]
    awayTeamId = awayTeam["id"]
    homeTeamLogo = http.get("https://images.fotmob.com/image_resources/logo/teamlogo/%d.png" % homeTeamId).body()
    awayTeamLogo = http.get("https://images.fotmob.com/image_resources/logo/teamlogo/%d.png" % awayTeamId).body()

    return render.Root(
        child = render.Box( # This Box exists to provide vertical centering
            render.Column(
                children = [
                    render.Row(
                        children=[
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = homeTeamLogo,
                                        width = 10,
                                        height = 10,
                                    ),
                                ],
                            ),
                            render.Text(" %s " % homeTeamName)
                        ]
                    ),
                    render.Row(
                        children=[
                            render.Text("    %s " % score)
                        ]
                    ),
                    render.Row(
                        children=[
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = awayTeamLogo,
                                        width = 10,
                                        height = 10,
                                    ),
                                ],
                            ),
                            render.Text(" %s" % awayTeam)
                        ],
                    )
                ],
            ),
        ),
    )
