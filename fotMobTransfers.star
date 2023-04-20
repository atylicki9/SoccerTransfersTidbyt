load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_LEAGUE = "47"
FOTMOB_BASE_URL = "https://www.fotmob.com/api/"
CACHE_TTL_SECONDS = 900

def main(config):
    allTransfers = getTransfersByLeague(config)
    currentTransferIndex = random.number(0,len(allTransfers)-1)
    currentTransfer = allTransfers[currentTransferIndex]
    transferDetails = getTransferDetails(currentTransfer)

    return render.Root(
        child = render.Box( 
            render.Column(
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
                                        width = 10,
                                        height = 10,
                                    ),
                                ],
                            ),
                            render.Text(" --> "),
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = transferDetails["toClubLogo"],
                                        width = 10,
                                        height = 10,
                                    ),
                                ],
                            ),
                        ]
                    ),
                    render.Row(
                        children=[
                            render.Marquee(
                                width=64,
                                offset_start = 10,
                                offset_end = 5,
                                child = render.Text(getTransferStatement(transferDetails))
                            )
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
    "transferDate": currentTransfer["transferDate"],
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
    
    if len(nameList) < 1: # only one name 
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
                                            transferDetails["formattedPlayerName"], 
                                            transferDetails["toClubName"])
    if  transferDetails["toClubName"] == "Free agent":
        return "%s: %s has been dropped by %s." % ( 
                                            transferDetails["transferDate"], 
                                            transferDetails["formattedPlayerName"], 
                                            transferDetails["fromClubName"])
    return "%s: %s signs for %s from %s%s" % ( 
                                            transferDetails["transferDate"], 
                                            transferDetails["formattedPlayerName"], 
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
                        display = "Serie A (Brazil)",
                        value = "268",
                    ),
                    schema.Option(
                        display = "MLS",
                        value = "130",
                    ),
                    schema.Option(
                        display = "Championship",
                        value = "48",
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