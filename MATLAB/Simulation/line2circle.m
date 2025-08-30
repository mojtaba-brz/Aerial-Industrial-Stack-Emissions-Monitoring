function [x,y] = line2circle(x_o,y_o,R, pos, y_sign)
x0 = x_o - pos(1);
y0 = y_o - pos(2);

theta = atan2(y0, x0);
T = [cos(theta) sin(theta);-sin(theta) cos(theta)];

X = T*[x0;y0];
x3 = X(1);

x1  = (x3^2-R^2)/x3;
y1  = y_sign * sqrt(x3^2-R^2 - x1^2);

x = T(:,1)'*[x1;y1] + pos(1);
y = T(:,2)'*[x1;y1] + pos(2);
end