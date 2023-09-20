# rv_bailbonds

Run this query on your MySQL database:

CREATE TABLE `bailbonds` (
 `citizenid` VARCHAR(50) NOT NULL,
 `name` VARCHAR(50) NOT NULL,
 `amount` BIGINT NOT NULL DEFAULT 0
);

ALTER TABLE players ADD bailowed INT DEFAULT 0

Copy the image in the /images directory to `qb-inventory/html/images`

Add the following to your qb-core/shared/items.lua:

['bondsman_tablet'] = {['name'] = 'bondsman_tablet', ['label'] = 'Bondsman Tablet', ['weight'] = 100, ['type'] = 'item', ['image'] = 'bondsman_tablet.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'View all of the bonds up for grabs!'},

Add the following to your qb-core/shared/jobs.lua:

['bondsman'] = {
    label = 'Bail Bondsman',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = {
            name = 'Helper',
            payment = 30
        },
        ['1'] = {
            name = 'Agent',
            payment = 40
        },
        ['2'] = {
            name = 'Captain',
            payment = 50
        },
        ['3'] = {
            name = 'Manager',
            payment = 60,
            isboss = true
        },
    },
},

Add the following event to qb-prison/client/main.lua

RegisterNetEvent('prison:client:SetTime', function(time)
	jailTime = time
end)