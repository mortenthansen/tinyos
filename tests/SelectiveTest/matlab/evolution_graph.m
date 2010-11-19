function evolution_graph(data, id, runs)

names = fields(data);
names = sortrows(names);

% events, energy, and propabilities
thresholds = cell(runs,1);
ei = cell(runs,1);
et = cell(runs,1);
er = cell(runs,1);

%% Get estimates from node

for n=1:length(names)
    nodes = data.(char(names(n)));
    node = get_node(nodes, id);
    
    [s e ext mat tok nam] = regexp(char(names(n)),'threshold(?<threshold>[0-9]*|VAR)_run(?<run>[0-9])*');
    threshold = nam.threshold;
    run = str2double(nam.run);
    
    if ~strcmp(threshold,'VAR')
        continue
    end
    
    thresholds{run} = node.Selective__THRESHOLD(:,2);
    ei{run} = node.Selective__MOTESTATS(:,4);
    et{run} = node.Selective__MOTESTATS(:,5);
    er{run} = node.Selective__MOTESTATS(:,6);

    
end

%% Create figures

legends = cell(runs,1);
figure('Name','Evolutions')

subplot(2,2,1)
for r=1:runs
    plot(thresholds{r})
    hold on
    legends{r} = sprintf('Run %d', r);
end
ylabel('Threshold [importance]')
xlabel('Time [#packets]')
title('Threshold')
%legend(legends)

subplot(2,2,2)
for r=1:runs
    plot(ei{r})
    hold on
end
ylabel('Energy Consumption [mC]')
xlabel('Time [#packets]')
title('EI')

subplot(2,2,3)
for r=1:runs
    plot(et{r})
    hold on
end
ylabel('Energy Consumption [mC]')
xlabel('Time [#packets]')
title('ET')

subplot(2,2,4)
for r=1:runs
    plot(er{r})
    hold on
end
ylabel('Energy Consumption [mC]')
xlabel('Time [#packets]')
title('ER')

function node = get_node(nodes, id)
for n=1:length(nodes)
    if nodes(n).id==id
        node = nodes(n);
        break
    end
end
