fs=dir('*.fig');
for f={fs.name}
h=openfig(f{:},'invisible');
nn = strrep(f{:},'fig','png');
saveas(h,nn);
close(h)
end