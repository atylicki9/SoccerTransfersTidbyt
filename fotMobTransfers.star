"""
Applet: SoccerTransferNews
Summary: Displays men's soccer transfers from 20+ leagues around the world
Description: Displays live Transfer News from around the world. 
"""

load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_LEAGUE = "47"
FOTMOB_BASE_URL = "https://www.fotmob.com/api/"
CACHE_TTL_SECONDS = 900

LOGO_DIMENSIONS = 10
TIDBYT_WIDTH = 64
TIDBYT_HEIGHT = 32

def main(config):
    allTransfers = getTransfersByLeague(config)
    currentTransferIndex = random.number(0,len(allTransfers)-1)
    currentTransfer = allTransfers[currentTransferIndex]
    transferDetails = getTransferDetails(currentTransfer)

    return render.Root(
        show_full_animation	= True,
        child = render.Box( 
            render.Column(
                expanded = True,
                main_align="space_between",
                children = [
                    render.Row(
                        expanded=True,
                        main_align = "center",
                        cross_align = "center",
                        children=[
                            render.Text("%s" % transferDetails["formattedPlayerName"])
                        ]
                    ),
                    render.Row(
                        expanded=True,
                        main_align="center", 
                        cross_align="center",
                        children=[
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = transferDetails["fromClubLogo"],
                                        width = LOGO_DIMENSIONS,
                                        height = LOGO_DIMENSIONS,
                                    ),
                                ],
                            ),
                            render.Text(" -> "),
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = transferDetails["toClubLogo"],
                                        width = LOGO_DIMENSIONS,
                                        height = LOGO_DIMENSIONS,
                                    ),
                                ],
                            ),
                        ]
                    ),
                    render.Row(
                        children=[
                            render.Box(color ="#8b0000", height = 10,
                            child = render.Marquee(
                                width=TIDBYT_WIDTH,
                                offset_start = TIDBYT_WIDTH,
                                offset_end = TIDBYT_WIDTH,
                                child = render.Text(getTransferStatement(transferDetails))
                            ))
                        ],
                    )
                ],
            ),
        ),
    )

def getTransfersByLeague(config):
    league = config.get("league", DEFAULT_LEAGUE) 
    transfersUrlAppend = "leagues?id=%s&tab=transfers&type=team&timeZone=Americe/New_York" % league
    fotMobUrl = FOTMOB_BASE_URL + transfersUrlAppend

    data = get_cachable_data(fotMobUrl)
    transfersByLeague = json.decode(data)["transfers"]["data"]
    return transfersByLeague

def getTransferDetails(currentTransfer):
  return {
    "playerName": currentTransfer["name"],
    "formattedPlayerName": formatPlayerName(currentTransfer["name"]),
    "transferDate": currentTransfer["transferDate"].split("T")[0],
    "fromClubId":  currentTransfer["fromClubId"],
    "fromClubName": currentTransfer["fromClub"],
    "toClubId": currentTransfer["toClubId"],
    "toClubName": currentTransfer["toClub"],
    "fromClubLogo": getClubLogo(currentTransfer["fromClubId"]),
    "toClubLogo": getClubLogo(currentTransfer["toClubId"]),
    "transferFeeStatement": getTransferFeeStatement(currentTransfer)
    }

def formatPlayerName(playerName):
    nameList = playerName.split(" ", 1)
    
    if len(nameList) < 2: # only one name 
        return playerName
    
    firstInitial = nameList[0][0]
    lastName = nameList[1]

    if len(lastName) > 9: # shorten long last names
        lastName = "%s..." % lastName[:8]
    
    formattedName = "%s. %s" % (firstInitial, lastName)
    return formattedName
    

def getClubLogo(clubId):
    logo = http.get("https://images.fotmob.com/image_resources/logo/teamlogo/%d.png" % clubId).body()
    if "png" in logo.lower():
        return logo
    else:
       return http.get("https://images.fotmob.com/image_resources/logo/teamlogo/10272.png").body() # default logo

def getTransferStatement(transferDetails):
    if transferDetails["fromClubName"] == "Free agent":
        return "%s: %s has been signed by %s." % ( 
                                            transferDetails["transferDate"], 
                                            transferDetails["playerName"], 
                                            transferDetails["toClubName"])
    if  transferDetails["toClubName"] == "Free agent":
        return "%s: %s has been dropped by %s." % ( 
                                            transferDetails["transferDate"], 
                                            transferDetails["playerName"], 
                                            transferDetails["fromClubName"])
    return "%s: %s signs for %s from %s%s" % ( 
                                            transferDetails["transferDate"], 
                                            transferDetails["playerName"], 
                                            transferDetails["toClubName"], 
                                            transferDetails["fromClubName"], 
                                            transferDetails["transferFeeStatement"])

def getTransferFeeStatement(transferDetails):
    if transferDetails["fee"] == None:
        return "." 
    transferType = transferDetails["fee"]["localizedFeeText"]
    if transferType == "transfer_type_free_transfer":
        return " on a free transfer."
    if transferType == "on_loan":
        return " on loan."
    if transferType == "transfer_fee":
        transferValue = transferDetails["fee"]["value"]
        return " for %s." % transferValue

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "league",
                name = "League",
                desc = "Select which league's transfers to display",
                icon = "futbol",
                default = "47",
                options = [
                    schema.Option(
                        display = "Premier League",
                        value = "47",
                    ),
                    schema.Option(
                        display = "La Liga",
                        value = "87"
                    ),
                    schema.Option(
                        display = "Bundesliga",
                        value = "54",
                    ),
                    schema.Option(
                        display = "Serie A",
                        value = "55",
                    ),
                    schema.Option(
                        display = "Ligue 1",
                        value = "53",
                    ),
                    schema.Option(
                        display = "Liga Portugal",
                        value = "61",
                    ),
                    schema.Option(
                        display = "Eredivisie",
                        value = "57",
                    ),
                    schema.Option(
                        display = "Liga Profesional (Argentina)",
                        value = "112",
                    ),
                    schema.Option(
                        display = "A-League (Australia)",
                        value = "113",
                    ),
                    schema.Option(
                        display = "Austrian Bundesliga",
                        value = "38",
                    ),
                    schema.Option(
                        display = "Belgian Pro League",
                        value = "40",
                    ),
                    schema.Option(
                        display = "Serie A (Brazil)",
                        value = "268",
                    ),
                    schema.Option(
                        display = "Canadian Premier League",
                        value = "9986",
                    ),
                    schema.Option(
                        display = "Chinese Super League",
                        value = "120",
                    ),
                    schema.Option(
                        display = "HNL (Croatia)",
                        value = "252",
                    ),
                    schema.Option(
                        display = "Superligaen (Denmark)",
                        value = "46",
                    ),
                    schema.Option(
                        display = "Championship (England)",
                        value = "48",
                    ),
                    schema.Option(
                        display = "League One (England)",
                        value = "108",
                    ),
                    schema.Option(
                        display = "League Two (England)",
                        value = "109",
                    ),
                    schema.Option(
                        display = "Irish Premier Division",
                        value = "126",
                    ),
                    schema.Option(
                        display = "Liga MX",
                        value = "230",
                    ),
                    schema.Option(
                        display = "Eliteserien (Norway)",
                        value = "59",
                    ),
                    schema.Option(
                        display = "Saudi Pro League",
                        value = "536",
                    ),
                    schema.Option(
                        display = "Scottish Premiership",
                        value = "64",
                    ),
                    schema.Option(
                        display = "Super Lig (Turkey)",
                        value = "71",
                    ),
                    schema.Option(
                        display = "MLS",
                        value = "130",
                    ),
                    schema.Option(
                        display = "USL Championship",
                        value = "8972",
                    ),
                ],
            )
        ]
    )

def get_cachable_data(url):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, res.body(), CACHE_TTL_SECONDS)

    return res.body()