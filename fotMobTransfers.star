load("render.star", "render")
load("http.star", "http")
load("random.star", "random")

FOTMOB_BASE_URL = "https://www.fotmob.com/api/"

def main(config):
    allTransfers = getTransfersByLeague(config)
    currentTransferIndex = random.number(1,50)
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
    # TODO: Condense this url generation code 
    # league = config.get("leagueId", "47") # TODO: add config
    transfersUrlAppend = "leagues?id=87&tab=transfers&type=team%timeZone=Americe/New_York" # TODO: make configurable
    fotMobUrl = FOTMOB_BASE_URL + transfersUrlAppend

    transfersByLeague = http.get(fotMobUrl) # TODO: Add caching daily
    
    if transfersByLeague.status_code != 200:
        fail("FotMob Transfers request failed with status %d", transfersByLeague.status_code)

    return transfersByLeague.json()["transfers"]["data"]

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
    
    if len(nameList) > 1:
        firstInitial = nameList[0][0]
        lastName = nameList[1]
        if len(lastName) > 9: # shorten long last names
            lastName = "%s..." % lastName[:8]

        formattedName = "%s. %s" % (firstInitial, lastName)
        return formattedName
    else:
        return playerName

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
        return " for a fee of %s." % transferValue
        