load("render.star", "render")
load("http.star", "http")

FOTMOB_BASE_URL = "https://www.fotmob.com/api/"

def main(config):

    # TODO: Condense this url generation code 
    # league = config.get("leagueId", "47") # TODO: add config
    transfersUrlAppend = "leagues?id=47&tab=transfers&type=team%timeZone=Americe/New_York" # TODO: make configurable
    fotMobUrl = FOTMOB_BASE_URL + transfersUrlAppend

    transfersByLeague = http.get(fotMobUrl) # TODO: Add caching daily
    
    if transfersByLeague.status_code != 200:
        fail("FotMob Transfers request failed with status %d", transfersByLeague.status_code)

    allTransfers = transfersByLeague.json()["transfers"]["data"]
    currentTransfer = allTransfers[4] # TODO: iterate over all transfers 

    playerName = currentTransfer["name"]
    fromClubId = currentTransfer["fromClubId"]
    fromClubName = currentTransfer["fromClub"]
    toClubId = currentTransfer["toClubId"]
    toClubName = currentTransfer["toClub"]
    fromClubLogo = http.get("https://images.fotmob.com/image_resources/logo/teamlogo/%d.png" % fromClubId).body()
    toClubLogo = http.get("https://images.fotmob.com/image_resources/logo/teamlogo/%d.png" % toClubId).body()

    
    transferFeeStatement = getTransferFeeStatement(currentTransfer)

    return render.Root(
        child = render.Box( 
            render.Column(
                children = [
                    render.Row(
                        children=[
                            render.Marquee(
                                width=70,
                                child=render.Text("%s " % playerName)
                            )
                        ]
                    ),
                    render.Row(
                        expanded=True, # Use as much horizontal space as possible
                        main_align="space_evenly", # Controls horizontal alignment
                        cross_align="center",
                        children=[
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = fromClubLogo,
                                        width = 10,
                                        height = 10,
                                    ),
                                ],
                            ),
                            render.Text(" --> "),
                            render.Animation(
                                children = [
                                    render.Image(
                                        src = toClubLogo,
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
                                child=render.Text(" %s has transfered from %s to %s %s" % (playerName, fromClubName, toClubName, transferFeeStatement)),
                            )
                        ],
                    )
                ],
            ),
        ),
    )

def getTransferFeeStatement(currentTransfer):
    transferType = currentTransfer["fee"]["localizedFeeText"]
    if transferType == "transfer_type_free_transfer":
        return "on a free transfer."
    if transferType == "on_loan":
        return "on loan."
    if transferType == "transfer_fee":
        transferValue = currentTransfer["fee"]["value"]
        return "for a fee of %s." % transferValue
    return "" # if there is no type here, just return empty string


